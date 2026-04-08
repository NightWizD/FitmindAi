from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.security import verify_token
from app.services.auth_service import get_user
import logging

logger = logging.getLogger(__name__)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    logger.info(f"Received token: {token[:50]}...")
    try:
        username = verify_token(token, credentials_exception)
        logger.info(f"Decoded username: {username}")
        user = await get_user(username)
        if user is None:
            logger.error(f"User not found for username in database: {username}")
            raise credentials_exception
        return user
    except HTTPException as e:
        # Re-raise HTTPExceptions as-is
        raise e
    except Exception as e:
        logger.error(f"Unexpected error in get_current_user: {str(e)}", exc_info=True)
        raise credentials_exception
