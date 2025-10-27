"""
Configuração de conexão com PostgreSQL usando SQLAlchemy
"""
import os
from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager

# Configuração do banco de dados
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://ocsuser:ocspassword@db:5432/ocsinventory"
)

# Engine do SQLAlchemy
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # Verifica conexão antes de usar
    pool_size=10,
    max_overflow=20
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para modelos ORM (se necessário no futuro)
Base = declarative_base()


def get_db():
    """
    Dependency para obter sessão do banco de dados
    Uso: db: Session = Depends(get_db)
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@contextmanager
def get_db_context():
    """
    Context manager para uso fora de rotas FastAPI
    Uso: with get_db_context() as db: ...
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_connection():
    """Testa conexão com o banco de dados"""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            return True
    except Exception as e:
        print(f"Erro ao conectar no banco: {e}")
        return False

