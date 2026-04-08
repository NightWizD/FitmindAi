from app.core.database import get_database
from app.core.security import verify_password, get_password_hash
from app.models.user import User
from app.schemas.user_metrics import UserMetrics
from app.schemas.user_goals import UserGoals
from app.schemas.user_food_preferences import UserFoodPreferences

async def get_user(username: str):
    db = get_database()
    user_doc = await db.users.find_one({"username": username})
    if user_doc:
        user_doc["_id"] = str(user_doc["_id"])
        return User(**user_doc)
    return None

async def authenticate_user(email: str, password: str):
    db = get_database()
    user_doc = await db.users.find_one({"email": email})
    if user_doc and verify_password(password, user_doc["hashed_password"]):
        user_doc["_id"] = str(user_doc["_id"])
        return User(**user_doc)
    return False

async def create_user(user):
    db = get_database()
    hashed_password = get_password_hash(user.password)
    user_instance = User(username=user.username, email=user.email, hashed_password=hashed_password)
    user_dict = user_instance.dict(by_alias=True, exclude={'id'})
    result = await db.users.insert_one(user_dict)
    user_dict["_id"] = str(result.inserted_id)
    return User(**user_dict)

async def save_user_metrics(current_user, metrics: UserMetrics):
    db = get_database()
    metrics_dict = metrics.dict()
    metrics_dict["user_id"] = str(current_user.id)
    metrics_dict["name"] = current_user.username

    # Calculate BMI if not provided
    if metrics_dict.get('bmi') is None:
        height_m = metrics_dict.get('height', 170) / 100
        weight = metrics_dict.get('weight', 70)
        if height_m > 0 and weight > 0:
            metrics_dict['bmi'] = weight / (height_m ** 2)

    result = await db.user_metrics.insert_one(metrics_dict)
    return result.inserted_id

async def save_user_goals(current_user, goals: UserGoals):
    db = get_database()
    goals_dict = goals.dict()
    goals_dict["user_id"] = str(current_user.id)
    goals_dict["name"] = current_user.username
    
    # Update existing goals if they exist, otherwise insert
    result = await db.user_goals.update_one(
        {"user_id": str(current_user.id)},
        {"$set": goals_dict},
        upsert=True
    )
    
    # Also update the primary user_metrics for consistency if needed
    if goals_dict.get("goals"):
        # We store both the primary goal (first one) and the full list in metrics
        await db.user_metrics.update_one(
            {"user_id": str(current_user.id)},
            {"$set": {
                "goal": goals_dict["goals"][0],
                "goals": goals_dict["goals"], # Full list of goals
                "weight_goal": goals_dict.get("weight_goal"),
                "calories_goal": goals_dict.get("calories_goal"),
                "gym_level": goals_dict.get("gym_level")
            }}
        )
    
    return result.upserted_id or str(current_user.id)

async def update_user_metrics(current_user, activity_level: str):
    db = get_database()
    await db.user_metrics.update_one(
        {"user_id": str(current_user.id)},
        {"$set": {"activity_level": activity_level}}
    )

async def get_user_metrics(current_user):
    db = get_database()
    # Check by both ID and Username to handle inconsistencies
    metrics = await db.user_metrics.find_one({
        "$or": [
            {"user_id": str(current_user.id)},
            {"user_id": current_user.username},
            {"name": current_user.username}
        ]
    })
    if metrics:
        metrics["_id"] = str(metrics["_id"])
        return metrics
    return None

async def get_user_food_preferences(current_user):
    db = get_database()
    prefs = await db.user_food_preferences.find_one({"user_id": str(current_user.id)})
    if prefs:
        prefs["_id"] = str(prefs["_id"])
        return prefs
    return None

async def save_user_food_preferences(current_user, prefs: UserFoodPreferences):
    db = get_database()
    prefs_dict = prefs.dict()
    prefs_dict["user_id"] = str(current_user.id)
    prefs_dict["name"] = current_user.username
    
    # Update existing preferences if they exist, otherwise insert
    result = await db.user_food_preferences.update_one(
        {"user_id": str(current_user.id)},
        {"$set": prefs_dict},
        upsert=True
    )
    
    # Sync with user_metrics for AI service access
    await db.user_metrics.update_one(
        {"user_id": str(current_user.id)},
        {"$set": {
            "food_preference": prefs_dict.get("food_preference"),
            "allergies": prefs_dict.get("allergies", [])
        }}
    )
    
    return result.upserted_id or str(current_user.id)

async def reset_password(current_user, new_password: str):
    db = get_database()
    hashed_password = get_password_hash(new_password)
    await db.users.update_one(
        {"username": current_user.username},
        {"$set": {"hashed_password": hashed_password}}
    )
