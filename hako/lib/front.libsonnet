local utils = import './utils.libsonnet';

{
  container: {
    cpu: 64,
    memory: 32,
    image_tag: 'docker.pkg.github.com/sorah/infra-hako-front/front:bee1c1b8206782a0e301d2b98a84005f73309f47',
    repository_credentials: utils.githubRepositoryCredentials,
  },
  script: {
    local default = {
      type: 'nginx_front',
      backend_host: 'localhost',
      s3: {
        region: 'us-west-2',
        bucket: 'nkmi-infra-ausw2',
        prefix: 'hako/front-config',
      },
    },
    default: default {
      locations: {
        '/': {
          https_type: 'always',
        },
      },
    },
  },
}
