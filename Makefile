CLUSTER_NAME = fargate-practice # ECSのクラスター名
PROFILE_NAME = pipopotamasu # ecs-cliのprofile名 -> ~> ~/.ecs/credentials
TASK_DEFINITION_NAME = fargate-practice
PRODUCTION_COMPOSE_FILE_NAME = production-docker-compose.yml
LOAD_BALANCER_NAME = test-yamato
ECS_SERVICE_NAME = fargate-practice
LOAD_BALANCING_CONTAINER_NAME = nginx
LOAD_BALANCING_CONTAINER_PORT = 80
TARGET_GROUP_ARN = arn:aws:elasticloadbalancing:ap-northeast-1:100535542918:targetgroup/fargate-practice-target/eef3f90a8a00d60b
TIME_OUT = 15
ECR_NGINX_REPO_NAME = nginx_custom
NGINX_DOCKER_FILE_PATH = ./nginx.Dockerfile
REGION = ap-northeast-1

# ECS commands
create_ecs_conf: # 手元の環境にecs-cliのconfigを作成する
	ecs-cli configure --cluster ${CLUSTER_NAME} --region ${REGION} --default-launch-type FARGATE --config-name ${CLUSTER_NAME}

create_ecs_credential: # 手元の環境にecs-cliのcredentialsを作成する。引数にAWS_ACCESS_KEY_IDとAWS_SECRET_ACCESS_KEYを渡してください
	ecs-cli configure profile --access-key ${AWS_ACCESS_KEY_ID} --secret-key ${AWS_SECRET_ACCESS_KEY} --profile-name ${PROFILE_NAME}

create_task_definition: # タスク定義の作成、すでに存在している場合はrevisionが上がる
	ecs-cli compose --project-name ${TASK_DEFINITION_NAME} --file ${PRODUCTION_COMPOSE_FILE_NAME} create --launch-type FARGATE

deploy: # クラスターにデプロイ(タスク定義の作成を含む)
	ecs-cli compose --project-name ${ECS_SERVICE_NAME} --file ${PRODUCTION_COMPOSE_FILE_NAME} service up --timeout ${TIME_OUT} --create-log-groups --aws-profile ${PROFILE_NAME} --cluster-config ${CLUSTER_NAME} --container-name ${LOAD_BALANCING_CONTAINER_NAME} --container-port ${LOAD_BALANCING_CONTAINER_PORT} --target-group-arn ${TARGET_GROUP_ARN}

deploy_ci: # CI用のデプロイコマンド
	ecs-cli compose --project-name ${ECS_SERVICE_NAME} --file ${PRODUCTION_COMPOSE_FILE_NAME} service up --timeout ${TIME_OUT} --create-log-groups --cluster-config ${CLUSTER_NAME} --container-name ${LOAD_BALANCING_CONTAINER_NAME} --container-port ${LOAD_BALANCING_CONTAINER_PORT} --target-group-arn ${TARGET_GROUP_ARN} --region ${REGION} --launch-type FARGATE

container_status: # クラスターの実行中コンテナ確認
	ecs-cli compose --project-name ${ECS_SERVICE_NAME} --file ${PRODUCTION_COMPOSE_FILE_NAME} service ps --cluster-config ${CLUSTER_NAME} --aws-profile ${PROFILE_NAME}

container_log: # コンテナログの出力・・・タスクidは「クラスターの実行中コンテナ確認」で確認できる。ただ、コンテナ毎のログ出力ができない(やれるのかもしれないが、やり方がわからない)
	ecs-cli logs --task-id ${TASK_ID} --follow --cluster-config ${CLUSTER_NAME} --aws-profile ${PROFILE_NAME}

scale: # 実行タスクの変更。SCALE_NUMを実行時に渡してください。
	ecs-cli compose --project-name ${ECS_SERVICE_NAME} --file ${PRODUCTION_COMPOSE_FILE_NAME} service scale ${SCALE_NUM} --timeout ${TIME_OUT} --cluster-config ${CLUSTER_NAME} --aws-profile ${PROFILE_NAME}

destroy: # サービスの削除(※触るな危険)
	ecs-cli compose --project-name ${ECS_SERVICE_NAME} --file ${PRODUCTION_COMPOSE_FILE_NAME} service down --timeout ${TIME_OUT} --cluster-config ${CLUSTER_NAME} --aws-profile ${PROFILE_NAME}

# AWS commands
aws_login:
	aws ecr get-login --no-include-email --region ${REGION} --profile ${PROFILE_NAME}

# Docker commands
build_nginx:
	docker image build -t ${ECR_NGINX_REPO_NAME} -f ${NGINX_DOCKER_FILE_PATH} .

nginx_tagging_image: # 引数にAWS_ACCOUNT_IDを渡してください
	docker tag ${ECR_NGINX_REPO_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/${ECR_NGINX_REPO_NAME}:latest

nginx_ecr_push:
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/${ECR_NGINX_REPO_NAME}:latest

nginx_build_and_ecr_push: # 引数にAWS_ACCOUNT_IDを渡してください
	make build_nginx
	make nginx_tagging_image
	make nginx_ecr_push