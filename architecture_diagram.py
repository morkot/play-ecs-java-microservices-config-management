from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import Lambda, Fargate, ECS
from diagrams.aws.network import ALB
from diagrams.aws.storage import S3
from diagrams.aws.integration import Eventbridge
from diagrams.aws.general import Users
from diagrams.onprem.iac import Terraform

# Graph attributes for better layout
graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho",
}

with Diagram(
    "ECS Java Microservices with Config Management",
    filename="architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):
    users = Users("Users")
    terraform = Terraform("Terraform\n(generates .env)")

    with Cluster("AWS Cloud"):
        with Cluster("VPC"):
            alb = ALB("ALB\n(Port 80)")

            with Cluster("ECS Cluster") as ecs_cluster:
                ecs_api = ECS("ECS API")

                with Cluster("Service-1"):
                    service1 = Fargate("Service-1\n(Java/Spring)\nPort 8080")

                with Cluster("Service-2"):
                    service2 = Fargate("Service-2\n(Java/Spring)\nPort 8081")

        with Cluster("Configuration Management"):
            s3 = S3("S3 Bucket\n.env files")
            eventbridge = Eventbridge("EventBridge\n(S3 Object Change)")
            lambda_fn = Lambda("Service Restart\nLambda")

    # User traffic flow
    users >> Edge(label="HTTP") >> alb
    alb >> Edge(label="/service-1/*") >> service1
    alb >> Edge(label="/service-2/*") >> service2

    # Terraform uploads .env files to S3
    terraform >> Edge(label="Upload .env files", color="green") >> s3

    # S3 env file configuration flow
    s3 >> Edge(label="environmentFiles\nat container start", style="dashed", color="blue") >> service1
    s3 >> Edge(label="environmentFiles\nat container start", style="dashed", color="blue") >> service2

    # Config update flow - Lambda calls ECS API to restart services
    s3 >> Edge(label=".env File Change", color="orange") >> eventbridge
    eventbridge >> Edge(label="Trigger Lambda", color="orange") >> lambda_fn
    lambda_fn >> Edge(label="update_service(\nforceNewDeployment=True)", color="red", penwidth="2.0") >> ecs_api
    ecs_api >> Edge(label="Restart Tasks", color="red", style="dashed") >> service1
    ecs_api >> Edge(label="Restart Tasks", color="red", style="dashed") >> service2
