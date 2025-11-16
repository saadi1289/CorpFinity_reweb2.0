from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from .config import DATABASE_URL
from sqlalchemy.engine import Engine


class Base(DeclarativeBase):
    pass


engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def ensure_schema():
    if not DATABASE_URL.startswith("sqlite"):
        return
    with engine.connect() as conn:
        rows = conn.exec_driver_sql("PRAGMA foreign_key_list('challenge_completions')").fetchall()
        has_user_fk = False
        for r in rows:
            try:
                table_name = r[2]
                from_col = r[3]
            except Exception:
                table_name = r[2] if 'table' in r._mapping else None
                from_col = r[3] if 'from' in r._mapping else None
            if table_name == 'users' and from_col == 'user_id':
                has_user_fk = True
                break
        if not has_user_fk:
            conn.exec_driver_sql("PRAGMA foreign_keys=OFF")
            conn.exec_driver_sql(
                """
                CREATE TABLE IF NOT EXISTS challenge_completions_new (
                    id INTEGER PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    challenge_id INTEGER NOT NULL,
                    pillar VARCHAR(100) NOT NULL,
                    energy_level VARCHAR(20) NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT uq_completion_user_challenge UNIQUE (user_id, challenge_id),
                    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
                    FOREIGN KEY(challenge_id) REFERENCES challenges(id) ON DELETE CASCADE
                )
                """
            )
            conn.exec_driver_sql(
                """
                INSERT INTO challenge_completions_new (id, user_id, challenge_id, pillar, energy_level, created_at)
                SELECT id, user_id, challenge_id, pillar, energy_level, created_at FROM challenge_completions
                """
            )
            conn.exec_driver_sql("DROP TABLE challenge_completions")
            conn.exec_driver_sql("ALTER TABLE challenge_completions_new RENAME TO challenge_completions")
            conn.exec_driver_sql("PRAGMA foreign_keys=ON")