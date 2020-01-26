local utils = import 'lib/utils.libsonnet';
local front = import 'public/lib/front.libsonnet';

{
  scheduler: utils.ecsSchedulerAusw2General() {
    service_discovery: [
      utils.serviceDiscoveryAusw2('front', 'hello-container'),
    ],
  },
  app: {
    image: 'docker.pkg.github.com/sorah/hello-container/app',
    repository_credentials: utils.githubRepositoryCredentials,
    cpu: 64,
    memory: 64,
    env: {
      RACK_ENV: 'production',
    },
    mount_points: [
    ],
    docker_labels: {
      'me.nkmi.hako.health-check-path': '/site/sha',
    },
  },
  additional_containers: {
    front: front.container,
  },
  volumes: {
  },
  scripts: [
    utils.githubTag('sorah/hello-container') {
      checks: ['build'],
    },
    front.script.default {
      backend_port: '8080',
    },
  ],
}
