# Container Linux Config
---
passwd:
  users:
    - name: core
      ssh_authorized_keys: 
      %{for key in machine.ssh_authorized_keys}
      - "${key}"
      %{endfor}
systemd:
  units:
    - name: gitlab-runner.service
      enabled: true
      contents: |
        [Unit]
        Description=Gitlab runner
        After=docker.service
        Requires=docker.service

        [Service]
        User=root
        TimeoutStartSec=0
        ExecStartPre=-/usr/bin/docker kill gitlab-runner
        ExecStartPre=-/usr/bin/docker container rm -f gitlab-runner
        ExecStartPre=-/usr/bin/docker volume create gitlab-runner-config
        ExecStart=/usr/bin/docker run --detach --name gitlab-runner --restart always \
          --volume gitlab-runner-config:/etc/gitlab-runner \
          --volume /var/run/docker.sock:/var/run/docker.sock \
          --privileged \
          --restart always \
          gitlab/gitlab-runner:latest

        [Install]
        WantedBy=multi-user.target      
    - name: gitlab-runner-registration.service
      enabled: true
      contents: |
        [Unit]
        Description=Gitlab runner registration
        After=gitlab-runner.service
        Requires=Requires=docker.service

        [Service]
        ExecStartPre=/bin/sleep 60
        ExecStart=/usr/bin/docker exec -- gitlab-runner sh -c "gitlab-runner register --non-interactive --url '${machine.runner.gitlab_url}' --registration-token '${machine.runner.registration_token}' --name ${machine.hostname} --executor docker --docker-volumes '/certs/client' --docker-privileged --env 'DOCKER_DRIVER=overlay2' --env 'DOCKER_TLS_CERTDIR=' --env 'DOCKER_HOST=tcp://docker:2375' --docker-image '${machine.runner.image}'"
        RemainAfterExit=true
        Type=oneshot

        [Install]
        WantedBy=multi-user.target  

storage:
  files:
  - path: /etc/hostname
    filesystem: "root"
    mode: 0644
    contents:
      inline: "${machine.hostname}"
networkd:
  units:
    - name: 00-vmware.network
      contents: |
        [Match]
        Name=ens192
        [Network]
        DHCP=%{if machine.network.ip_allocation_mode == "MANUAL"}no%{else}yes%{endif}
        DNS=${org_network.dns1}
        DNS=${org_network.dns2}
        %{if machine.network.ip_allocation_mode == "MANUAL"}
        [Address]
        Address=${machine.network.ip}/24
        %{endif}
        [Route]
        Destination=0.0.0.0/0
        Gateway=${org_network.gateway}