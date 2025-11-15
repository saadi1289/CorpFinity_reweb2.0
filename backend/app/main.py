from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from .database import Base, engine, get_db
from .models import User, Challenge, ChallengeStep, ChallengeCompletion
from .schemas import UserCreate, UserOut, Token, LoginRequest, RefreshRequest
from .auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    get_current_user,
)


Base.metadata.create_all(bind=engine)

app = FastAPI(title="CorpFinity Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/auth/register", response_model=Token)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter((User.email == user_in.email) | (User.username == user_in.username)).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User already exists")
    user = User(
        username=user_in.username,
        email=user_in.email,
        hashed_password=hash_password(user_in.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    access = create_access_token(user.email)
    refresh = create_refresh_token(user.email)
    return Token(access_token=access, refresh_token=refresh)


@app.post("/auth/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    access = create_access_token(user.email)
    refresh = create_refresh_token(user.email)
    return Token(access_token=access, refresh_token=refresh)


@app.post("/auth/refresh", response_model=Token)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)):
    from .auth import decode_token, create_access_token, create_refresh_token

    payload = decode_token(body.token)
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
    subject = payload.get("sub")
    access = create_access_token(subject)
    refresh = create_refresh_token(subject)
    return Token(access_token=access, refresh_token=refresh)


@app.get("/auth/me", response_model=UserOut)
def me(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    user = get_current_user(token, db)
    return UserOut(id=user.id, username=user.username, email=user.email)
@app.get("/challenges")
def list_challenges(pillar: str | None = None, energy_level: str | None = None, db: Session = Depends(get_db)):
    q = db.query(Challenge)
    if pillar:
        q = q.filter(Challenge.pillar == pillar)
    if energy_level:
        q = q.filter(Challenge.energy_level == energy_level)
    items = q.order_by(Challenge.pillar, Challenge.energy_level, Challenge.number).all()
    out = []
    for c in items:
        steps = db.query(ChallengeStep).filter(ChallengeStep.challenge_id == c.id).order_by(ChallengeStep.order).all()
        out.append({
            "id": c.id,
            "pillar": c.pillar,
            "energy_level": c.energy_level,
            "number": c.number,
            "name": c.name,
            "duration_minutes": c.duration_minutes,
            "description": c.description,
            "steps": [s.text for s in steps],
        })
    return {"items": out}


@app.get("/challenges/next")
def next_challenge(pillar: str, energy_level: str, token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    user = get_current_user(token, db)
    challenges = db.query(Challenge).filter(
        Challenge.pillar == pillar,
        Challenge.energy_level == energy_level,
    ).order_by(Challenge.number).all()
    if not challenges:
        return {"item": None}
    completed_ids = {
        c.challenge_id for c in db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == user.id,
            ChallengeCompletion.pillar == pillar,
            ChallengeCompletion.energy_level == energy_level,
        ).all()
    }
    choice = None
    for c in challenges:
        if c.id not in completed_ids:
            choice = c
            break
    if choice is None:
        db.query(ChallengeCompletion).filter(
            ChallengeCompletion.user_id == user.id,
            ChallengeCompletion.pillar == pillar,
            ChallengeCompletion.energy_level == energy_level,
        ).delete()
        db.commit()
        choice = challenges[0]
    steps = db.query(ChallengeStep).filter(ChallengeStep.challenge_id == choice.id).order_by(ChallengeStep.order).all()
    return {
        "item": {
            "id": choice.id,
            "pillar": choice.pillar,
            "energy_level": choice.energy_level,
            "number": choice.number,
            "name": choice.name,
            "duration_minutes": choice.duration_minutes,
            "description": choice.description,
            "steps": [s.text for s in steps],
        }
    }


@app.post("/challenges/{challenge_id}/complete")
def complete_challenge(challenge_id: int, token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    user = get_current_user(token, db)
    c = db.query(Challenge).filter(Challenge.id == challenge_id).first()
    if not c:
        raise HTTPException(status_code=404, detail="Challenge not found")
    existing = db.query(ChallengeCompletion).filter(
        ChallengeCompletion.user_id == user.id,
        ChallengeCompletion.challenge_id == challenge_id,
    ).first()
    if not existing:
        db.add(ChallengeCompletion(
            user_id=user.id,
            challenge_id=challenge_id,
            pillar=c.pillar,
            energy_level=c.energy_level,
        ))
        db.commit()
    return {"status": "ok"}