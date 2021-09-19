resource "aws_iam_role" "eks-worker-role" {
    name = "eks-worker-role"

    assume_role_policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Action = "sts:AssumeRole"
                    Effect = "Allow"
                    Principal = {
                        Service = "ec2.amazonaws.com"
                    }
                }
            ]
    })

}

resource "aws_iam_role_policy_attachment" "eks-worker-role-AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks-worker-role.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-role-AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks-worker-role.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-role-AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks-worker-role.name
}

resource "aws_eks_node_group" "eks-node-group1" {
    cluster_name    = aws_eks_cluster.eks-cluster.name
    node_group_name = "worker-group-1"
    node_role_arn   = aws_iam_role.eks-worker-role.arn
    subnet_ids      = [aws_subnet.eks-private-1a-subnet.id, aws_subnet.eks-private-1b-subnet.id]
    # default
    instance_types  = ["t3.medium"]
    scaling_config {
        desired_size = 3
        max_size     = 3
        min_size     = 1
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks-worker-role-AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.eks-worker-role-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.eks-worker-role-AmazonEC2ContainerRegistryReadOnly,
    ]
}