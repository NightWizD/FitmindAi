import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId

async def main():
    client = AsyncIOMotorClient('mongodb+srv://rudraphoto21_db_user:idgOyjweq3sWp74b@cluster0.wudlybj.mongodb.net/fitmind_ai?appName=Cluster0')
    db = client.get_database('fitmind_ai')
    doc = await db.user_workout_plans.find_one({'_id': ObjectId('69cf9246c26ff30b7c878ea4')})
    print(doc is not None)

if __name__ == '__main__':
    asyncio.run(main())
