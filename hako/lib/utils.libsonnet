{
  ecrRepository(name):: std.format('341857463381.dkr.ecr.us-west-2.amazonaws.com/%s', name),
  iamRole(name):: std.format('arn:aws:iam::341857463381:role/%s', name),

  ecsScheduler(region, cluster):: {
    type: 'ecs',
    region: region,
    cluster: cluster,
    // role: 'aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS',
    task_role_arn: $.iamRole('ecs-hako-general'),
    execution_role_arn: $.iamRole('ecsexec-hako-general'),
    desired_count: 1,
  },

  ecsSchedulerAusw2General():: self.ecsScheduler('us-west-2', 'nkmi-ausw2-general') {
  },

  serviceDiscoveryAusw2(container_name, name, port=80):: {
    container_name: container_name,
    container_port: port,
    service: {
      name: name,
      namespace_id: 'ns-mdciidima4pyqntu',
      dns_config: {
        dns_records: [{ type: 'SRV', ttl: 20 }],
      },
    },
  },

  codebuildTag(projectName):: {
    type: 'codebuild_tag',
    region: 'us-west-2',
    project: projectName,
  },

  githubTag(repo):: {
    type: 'github_status_tag',
    repo: repo,
    checks: ['build'],
  },

  githubRepositoryCredentials: {
    credentials_parameter: 'arn:aws:secretsmanager:us-west-2:341857463381:secret:hako/repo/github-EdWPBR',
  },
}
