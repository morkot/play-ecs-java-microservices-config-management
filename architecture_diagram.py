from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import Lambda, Fargate, ECS
from diagrams.aws.network import ALB
from diagrams.aws.management import SystemsManager
from diagrams.aws.integration import Eventbridge
from diagrams.aws.general import Users

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
            ssm = SystemsManager("SSM Parameter\nStore\n/ecs-config-demo/*")
            eventbridge = Eventbridge("EventBridge\n(SSM Change Events)")
            lambda_fn = Lambda("Service Restart\nLambda")

    # User traffic flow
    users >> Edge(label="HTTP") >> alb
    alb >> Edge(label="/service-1/*") >> service1
    alb >> Edge(label="/service-2/*") >> service2

    # SSM configuration flow
    service1 >> Edge(label="Read Config\nat startup", style="dashed", color="blue") >> ssm
    service2 >> Edge(label="Read Config\nat startup", style="dashed", color="blue") >> ssm

    # Config update flow - Lambda calls ECS API to restart services
    ssm >> Edge(label="Parameter Change", color="orange") >> eventbridge
    eventbridge >> Edge(label="Trigger Lambda", color="orange") >> lambda_fn
    lambda_fn >> Edge(label="update_service(\nforceNewDeployment=True)", color="red", penwidth="2.0") >> ecs_api
    ecs_api >> Edge(label="Restart Tasks", color="red", style="dashed") >> service1
    ecs_api >> Edge(label="Restart Tasks", color="red", style="dashed") >> service2
