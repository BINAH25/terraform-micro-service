import boto3
import time
import json

rds = boto3.client('rds')
ecs = boto3.client('ecs')

# Replica DB instance identifiers
replica_id = "postgres-db-replica-replica"
replica_mysql = "mysql-db-replica-replica"

# ECS services and cluster name
ecs_cluster_name = "micro-service-cluster"
ecs_services = [
    "django-queue-recovery",
    "django-recovery",
    "flask-queue-recovery",
    "flask-recovery",
    "frontend-recovery"
]

def is_already_promoted(db_instance):
    return not db_instance.get('ReadReplicaSourceDBInstanceIdentifier')

def update_ecs_services():
    for service_name in ecs_services:
        try:
            print(f"🔄 Updating ECS service {service_name} to desired count 1...")
            ecs.update_service(
                cluster=ecs_cluster_name,
                service=service_name,
                desiredCount=1
            )
            print(f"✅ Service {service_name} updated.")
        except Exception as e:
            print(f"❌ Error updating ECS service {service_name}: {str(e)}")

def lambda_handler(event, context):
    try:
        print("Checking replica status...")

        db_info = rds.describe_db_instances(DBInstanceIdentifier=replica_mysql)
        db_instance = db_info["DBInstances"][0]

        mysql_info = rds.describe_db_instances(DBInstanceIdentifier=replica_id)
        myqsl_db_instance = mysql_info["DBInstances"][0]

        if is_already_promoted(db_instance):
            print("✅ Postgres Replica is already promoted.")
        elif is_already_promoted(myqsl_db_instance):
            print("✅ MySQL Replica is already promoted.")
        else:
            print("Promoting replicas...")
            try:
                rds.promote_read_replica(DBInstanceIdentifier=replica_id)
                rds.promote_read_replica(DBInstanceIdentifier=replica_mysql)
            except Exception as e:
                print(f"⚠️ Promotion may be in progress: {e}")

            print("⏳ Waiting for promotion to complete...")
            waiter = rds.get_waiter('db_instance_available')
            waiter.wait(DBInstanceIdentifier=replica_id, WaiterConfig={'Delay': 120, 'MaxAttempts': 20})
            waiter.wait(DBInstanceIdentifier=replica_mysql, WaiterConfig={'Delay': 120, 'MaxAttempts': 20})
            print("✅ Replicas promoted.")

        # Update ECS services
        update_ecs_services()

        return {
            "status": "success",
            "message": "RDS promoted and ECS services updated."
        }

    except Exception as e:
        print("❌ Error:", str(e))
        return {"status": "error", "message": str(e)}
