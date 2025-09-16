# nomad-jobs/hello-world.nomad
job "hello-world" {
  datacenters = ["azure-east-us"]
  type = "service"

  group "web" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    service {
      name = "hello-world"
      port = "http"

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
        volumes = ["local:/usr/share/nginx/html"]
      }

      template {
        data = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Hello World - Nomad on Azure</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 50px;
            margin: 0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            margin: 0 auto;
            max-width: 600px;
        }
        h1 { font-size: 3rem; margin-bottom: 20px; }
        .info { margin: 20px 0; }
        .info div { margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Hello World from Nomad!</h1>
        <div class="info">
            <div><strong>Allocation:</strong> {{ env "NOMAD_ALLOC_NAME" }}</div>
            <div><strong>Task:</strong> {{ env "NOMAD_TASK_NAME" }}</div>
            <div><strong>Datacenter:</strong> {{ env "NOMAD_DC" }}</div>
            <div><strong>Node:</strong> {{ env "NODE_NAME" }}</div>
        </div>
        <p>Successfully running on Azure with HashiCorp Nomad!</p>
        <p><em>MLOps Engineer Assessment - Infrastructure as Code</em></p>
    </div>
</body>
</html>
EOF
        destination = "local/index.html"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
