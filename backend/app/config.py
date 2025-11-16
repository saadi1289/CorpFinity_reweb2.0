import os
from datetime import timedelta

SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key-change-me")
ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.environ.get("REFRESH_TOKEN_EXPIRE_MINUTES", "10080"))

_supabase_url = os.environ.get("SUPABASE_DB_URL")
_neon_url = os.environ.get("NEON_DATABASE_URL")
_vercel_pg_url = os.environ.get("POSTGRES_URL")
_vercel_pg_url_np = os.environ.get("POSTGRES_URL_NON_POOLING")
_db_url_unpooled = os.environ.get("DATABASE_URL_UNPOOLED")

def _normalize_pg_url(url: str) -> str:
    u = url
    if "+psycopg2" not in u and u.startswith("postgres"):
        u = u.replace("postgres://", "postgresql+psycopg2://").replace("postgresql://", "postgresql+psycopg2://")
    if "sslmode=" not in u and (".supabase.co" in u or ".neon.tech" in u or os.environ.get("DB_SSLMODE") == "require"):
        sep = "&" if "?" in u else "?"
        u = f"{u}{sep}sslmode=require"
    return u

if _neon_url:
    DATABASE_URL = _normalize_pg_url(_neon_url)
elif _supabase_url:
    DATABASE_URL = _normalize_pg_url(_supabase_url)
elif "DATABASE_URL" in os.environ:
    DATABASE_URL = _normalize_pg_url(os.environ["DATABASE_URL"])
elif _vercel_pg_url:
    DATABASE_URL = _normalize_pg_url(_vercel_pg_url)
elif _vercel_pg_url_np:
    DATABASE_URL = _normalize_pg_url(_vercel_pg_url_np)
elif _db_url_unpooled:
    DATABASE_URL = _normalize_pg_url(_db_url_unpooled)
else:
    _pg_host = os.environ.get("POSTGRES_HOST") or os.environ.get("PGHOST") or "localhost"
    _pg_db = os.environ.get("POSTGRES_DB") or os.environ.get("PGDATABASE")
    _pg_user = os.environ.get("POSTGRES_USER") or os.environ.get("PGUSER")
    _pg_pass = os.environ.get("POSTGRES_PASSWORD") or os.environ.get("PGPASSWORD")
    _pg_port = os.environ.get("POSTGRES_PORT") or os.environ.get("PGPORT") or "5432"
    if not _pg_db or not _pg_user:
        raise RuntimeError("PostgreSQL config required: set DATABASE_URL or POSTGRES/PG env vars")
    _auth = f"{_pg_user}:{_pg_pass}@" if _pg_pass else f"{_pg_user}@"
    DATABASE_URL = _normalize_pg_url(f"postgresql+psycopg2://{_auth}{_pg_host}:{_pg_port}/{_pg_db}")

def access_token_expiry() -> timedelta:
    return timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

def refresh_token_expiry() -> timedelta:
    return timedelta(minutes=REFRESH_TOKEN_EXPIRE_MINUTES)