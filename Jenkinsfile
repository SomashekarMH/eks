pipeline {

    agent any

    parameters {
        choice(
            name: 'terraform_command',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select the Terraform command to execute.'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    dir("terraform") {
                        git url: 'https://github.com/SomashekarMH/eks.git', branch: 'main'
                    }
                }
            }
        }

        stage('plan') {
            steps {
                sh '''
                    pwd
                    cd EKS/
                    terraform init
                '''
                sh '''
                    pwd
                    cd EKS/
                    terraform plan -out=tfplan
                '''
                sh '''
                    pwd
                    cd EKS/
                    terraform show -no-color tfplan > tfplan.txt
                '''
            }
        }

        stage('approve') {
            steps {
                script {
                    def plan = readFile('EKS/tfplan.txt')

                    input(
                        message: "Terraform Plan:\n${plan}\n\nDo you want to apply this plan?",
                        ok: 'Apply',
                        parameters: [
                            text(
                                name: 'approval',
                                defaultValue: 'yes',
                                description: 'Type "yes" to approve the plan.'
                            )
                        ]
                    )
                }
            }
        }

        stage('apply or destroy') {
            when {
                expression {
                    params.terraform_command == 'apply' ||
                    params.terraform_command == 'destroy'
                }
            }

            steps {
                script {
                    if (params.terraform_command == 'apply') {
                        sh '''
                            pwd
                            cd EKS/
                            terraform apply -input=false tfplan
                        '''
                    } else if (params.terraform_command == 'destroy') {
                        sh '''
                            pwd
                            cd EKS/
                            terraform destroy -auto-approve
                        '''
                    }
                }
            }
        }

    }
}