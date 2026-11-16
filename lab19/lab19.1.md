# Laboratorio 19.1 - Contenedores con Docker en Debian

## Objetivo

- Instalar Docker en la VM Debian y comprobar que el servicio quedó andando.
- Probar la instalación con la imagen `hello-world`.
- Levantar un servidor web Apache con una sola línea y verlo con `curl`.
- Abrirlo desde el navegador de la anfitriona con una regla de reenvío de puertos de VirtualBox.
- Dejar la VM como estaba: sin contenedores y con Docker instalado pero sin arrancar solo.

### Punto de partida

- La VM Debian del curso, con la cuenta administradora (por ejemplo `cristian`) y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md) (puerto 2222).
- Conexión a Internet en la VM, para bajar los paquetes y las imágenes (unos 110 MB de paquetes y 120 MB de imágenes).

No hace falta haber hecho otros laboratorios. Los pasos funcionan aunque Docker ya esté instalado. La teoría está en la [clase 20](https://linux.idepba.com.ar/clase20.html).

> [!NOTE]
> Reemplazá `cristian` por tu usuario. Los identificadores de contenedor, los nombres al azar, las fechas, los PID y los tiempos de tus salidas van a ser otros. `sudo` te va a pedir la contraseña la primera vez.

> [!WARNING]
> Si usás esta VM para algo más y Docker ya tiene contenedores tuyos, el paso final los borra todos. Hacé este laboratorio en una VM sin contenedores propios.

### Dónde se trabaja

- **En la Debian.** Una terminal con `ssh -p 2222 cristian@localhost`. El prompt dice `cristian@lab2-vm`.
- **En la anfitriona.** La terminal de tu equipo (PowerShell en Windows) y el navegador. Solo se usan en los pasos que lo indican.

## 1. Instalar Docker

Usamos los paquetes de Debian, que se instalan y se actualizan con `apt` como cualquier otro. `docker.io` trae el servicio y el cliente. `docker-compose` agrega el comando `docker compose`, que solo vamos a comprobar. `curl` lo usamos más adelante, porque la VM no lo trae.

**En la Debian:**

```bash
sudo apt update
sudo apt install -y docker.io docker-compose curl
```

La instalación baja unos 110 MB y trae 42 paquetes, entre ellos `containerd` y `runc`, que son los que realmente crean los contenedores. Lo importante está al principio y al final de la salida:

```text
Installing:
  curl  docker-compose  docker.io
...
Summary:
  Upgrading: 0, Installing: 42, Removing: 0, Not Upgrading: 8
  Download size: 109 MB
  Space needed: 465 MB / 17,3 GB available
```

Los números pueden cambiar con las actualizaciones. Si ya tenías algún paquete, la lista es más corta. Ahora comprobamos el servicio y las versiones:

```bash
systemctl status docker --no-pager
systemctl is-enabled docker docker.socket
docker --version
docker compose version
```

```text
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-11-15 19:51:04 -03; 14s ago
 Invocation: 046048a12018471c9d7bf0c59d3c877e
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 1702 (dockerd)
      Tasks: 8
     Memory: 28.6M (peak: 29.4M)
        CPU: 181ms
     CGroup: /system.slice/docker.service
             └─1702 /usr/sbin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
enabled
enabled
Docker version 26.1.5+dfsg1, build a72d7cd
Docker Compose version 2.26.1-4
```

En Debian, el paquete deja Docker activo y habilitado: arranca solo con la VM. Fijate también en `TriggeredBy: docker.socket`. Hay dos unidades: `docker.service` es el servicio (`dockerd`) y `docker.socket` es el socket por el que el cliente le habla. Más abajo importa tener presentes las dos.

Las versiones de `docker --version` y `docker compose version` dependen de la versión de Debian que tengas (acá, Debian 13). Si `systemctl status` no dice `active (running)`, arrancalo con `sudo systemctl enable --now docker`.

### Por qué `sudo docker`

El cliente `docker` le habla a `dockerd` por un socket que solo pueden usar `root` y el grupo `docker`:

```bash
ls -l /var/run/docker.sock
id -nG
docker ps
```

```text
srw-rw---- 1 root docker 0 nov 15 19:51 /var/run/docker.sock
cristian cdrom floppy sudo audio dip video plugdev users netdev bluetooth
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.45/containers/json": dial unix /var/run/docker.sock: connect: permission denied
```

Tu usuario no está en el grupo `docker` y por eso `docker ps` falla. Podrías agregarlo, pero quien está en ese grupo equivale a `root` (la [clase 20](https://linux.idepba.com.ar/clase20.html) lo explica en «El grupo docker»). Por eso en todo el laboratorio usamos `sudo docker`: cada uso queda como una decisión de quien lo escribe.

## 2. El primer contenedor: `hello-world`

```bash
sudo docker run hello-world
```

```text
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pull complete
Digest: sha256:cf1b20a0c89a666b6950fecda7ccbc1b1a86520e7c53f908f3a21e79d0d60458
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

Se recortó el progreso de la descarga y el texto que sigue, que explica los pasos y ofrece más ejemplos. El mensaje cuenta los pasos que siguió Docker: el cliente le pidió el trabajo al servicio, el servicio no tenía la imagen `hello-world` y la bajó de Docker Hub, creó un contenedor con ella y lo ejecutó, y mandó la salida a tu terminal. El programa imprimió el mensaje y terminó, y con él terminó el contenedor. Si volvés a correr el comando, ya no baja nada, porque la imagen quedó guardada.

Un contenedor que terminó no desaparece. Con `-a` se ven también los que ya no corren:

```bash
sudo docker ps -a
sudo docker images
```

```text
CONTAINER ID   IMAGE         COMMAND    CREATED        STATUS                              PORTS     NAMES
201afa0e229f   hello-world   "/hello"   1 second ago   Exited (0) Less than a second ago             charming_leavitt
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
hello-world   latest    e2ac70e7319a   7 months ago   10.1kB
```

El contenedor está `Exited (0)`: terminó sin error. Como no le pusimos nombre, Docker eligió uno al azar (`charming_leavitt` acá, el tuyo será otro). La imagen pesa 10 kB, porque el programa es un único archivo.

## 3. Un servidor web en una línea

Apache viene en la imagen oficial `httpd`, versión `2.4`:

```bash
sudo docker run -d --name web -p 8080:80 httpd:2.4
```

```text
Unable to find image 'httpd:2.4' locally
2.4: Pulling from library/httpd
...
Status: Downloaded newer image for httpd:2.4
fc08b594b4f5efef3fbe10aaa5820eb39cea36858af1951ee513a3d4c04d0f50
```

Se recortó la lista de capas que se descargan. La última línea es el identificador completo del contenedor. Lo que significa cada opción:

- `-d` lo deja corriendo en segundo plano y devuelve la terminal.
- `--name web` le da un nombre propio, para no usar el identificador.
- `-p 8080:80` publica un puerto: lo que llegue al puerto 8080 de la VM va al puerto 80 del contenedor, donde escucha Apache. Va primero el de la VM y después el del contenedor.
- `httpd:2.4` es la imagen.

No instalamos Apache ni tocamos su configuración. Comprobamos que está corriendo y le pedimos la página:

```bash
sudo docker ps
curl http://localhost:8080
```

```text
CONTAINER ID   IMAGE       COMMAND              CREATED        STATUS                  PORTS                                   NAMES
fc08b594b4f5   httpd:2.4   "httpd-foreground"   1 second ago   Up Less than a second   0.0.0.0:8080->80/tcp, :::8080->80/tcp   web
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>
```

`0.0.0.0:8080->80/tcp` es el puerto publicado: escucha en todas las direcciones de la VM. La página dice `It works!`. Lo que Apache escribe en su registro se ve con `docker logs`:

```bash
sudo docker logs web
```

```text
172.17.0.1 - - [15/Nov/2026:22:51:38 +0000] "GET / HTTP/1.1" 200 191
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
[Sun Nov 15 22:51:37.856698 2026] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache/2.4.71 (Unix) configured -- resuming normal operations
[Sun Nov 15 22:51:37.857022 2026] [core:notice] [pid 1:tid 1] AH00094: Command line: 'httpd -D FOREGROUND'
```

La primera línea es el pedido de `curl`. El aviso `AH00558` es normal: la imagen no define un nombre de servidor y Apache lo informa, pero funciona igual. `172.17.0.1` es la VM vista desde la red interna de Docker. Las líneas de Apache salen por dos salidas distintas, así que su orden puede cambiar.

Si algo no da lo que se espera:

- `Bind for 0.0.0.0:8080 failed: port is already allocated`: el 8080 de la VM ya lo usa otro contenedor. Buscalo con `sudo docker ps` y borralo, o elegí otro puerto, por ejemplo `-p 8081:80`.
- `Conflict. The container name "/web" is already in use`: ya hay un contenedor con ese nombre, quizás de un intento anterior. Borralo con `sudo docker rm -f web` y repetí el `run`.
- `curl` dice `Connection refused` o `Recv failure` justo después del `run`: Apache tarda un segundo en arrancar. Repetí el `curl`.

## 4. Abrirlo desde el navegador de la anfitriona

El `curl` anduvo porque corrió dentro de la VM. El navegador de tu equipo está afuera, y la VM usa un adaptador de red en NAT: desde la anfitriona no se puede llegar al puerto 8080 de la VM sin una regla de reenvío, igual que pasaba con el SSH en el [Laboratorio 3](../lab3/lab3.md#0-preparación-reenvío-de-puertos-en-virtualbox). El camino es:

```text
Navegador: localhost:8080  →  VirtualBox NAT  →  VM:8080  →  Docker  →  contenedor:80
```

Agregá una regla nueva, por la parte gráfica o por la terminal.

### Por la interfaz gráfica

Igual que en el Laboratorio 3, con la VM **apagada** (`sudo poweroff`). Si no querés apagarla, usá la terminal, más abajo.

1. En VirtualBox, seleccioná la VM `Lab2` y abrí **Configuración**.
2. Entrá en **Red** → **Adaptador 1** → **Reenvío de puertos**. Ya está la regla del puerto 2222 para SSH.
3. Agregá una regla nueva:

| Nombre | Protocolo | IP Anfitrión | Puerto anfitrión | IP invitado | Puerto invitado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| web | TCP |  | 8080 |  | 8080 |

Los campos **IP anfitrión** e **IP invitado** quedan vacíos. Aceptá los cambios.

### Por la terminal

En la terminal de la anfitriona, con la VM encendida y sin reiniciarla (si tu VM no se llama `Lab2`, cambiá el nombre):

```bash
VBoxManage controlvm Lab2 natpf1 "web,tcp,,8080,,8080"
VBoxManage showvminfo Lab2 --machinereadable | grep Forwarding
```

```text
Forwarding(0)="Rule 1,tcp,,2222,,22"
Forwarding(1)="web,tcp,,8080,,8080"
```

En Windows, si `VBoxManage` no se reconoce, está en `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`.

### Probar

En la anfitriona, abrí el navegador en `http://localhost:8080`. Tiene que mostrar el mensaje `It works!`:

![Página «It works!» de Apache vista desde el navegador de la anfitriona en http://localhost:8080](../img/lab19/web-docker.png)

Si querés probarlo también por la terminal de la anfitriona: `curl http://localhost:8080` (en PowerShell, `curl.exe http://localhost:8080`).

Si el navegador no conecta:

- Mirá que el contenedor siga corriendo (`sudo docker ps` en la VM) y que `curl http://localhost:8080` ande dentro de la VM.
- Mirá que la regla exista (`VBoxManage showvminfo Lab2 --machinereadable | grep Forwarding`) y que los puertos sean los de la tabla.
- Si el 8080 de la anfitriona ya está ocupado por otro programa, VirtualBox no puede abrirlo. Usá otro puerto de anfitrión, por ejemplo 8082, con la regla `web,tcp,,8082,,8080`, y abrí `http://localhost:8082`.
- Probá con `http://127.0.0.1:8080`, por si `localhost` apunta a IPv6.

### El pedido en el registro

Volvé a la VM y mirá qué anotó Apache de las visitas del navegador:

```bash
sudo docker logs web 2>&1 | grep GET
```

```text
172.17.0.1 - - [15/Nov/2026:22:51:38 +0000] "GET / HTTP/1.1" 200 191
10.0.2.2 - - [15/Nov/2026:22:51:45 +0000] "GET / HTTP/1.1" 200 191
10.0.2.2 - - [15/Nov/2026:22:51:46 +0000] "GET / HTTP/1.1" 200 191
10.0.2.2 - - [15/Nov/2026:22:51:46 +0000] "GET /favicon.ico HTTP/1.1" 404 236
```

La primera línea es la del `curl` de la VM. Las demás son de la anfitriona: llegan desde `10.0.2.2`, que es la anfitriona vista desde la red NAT de VirtualBox. El `404` de `/favicon.ico` es el navegador pidiendo el ícono de la pestaña, que Apache no tiene. En tu salida va a haber una línea por cada vez que abriste o recargaste la página.

## 5. Dejar la VM como estaba

Docker se queda instalado, pero sin contenedores y sin arrancar solo.

### Borrar los contenedores

```bash
sudo docker rm -f web
sudo docker container prune -f
sudo docker ps -a
```

```text
web
Deleted Containers:
956a97a69386761c1c62c8dba1decea337ab47b5f686d3856da07fed71f0f77a

Total reclaimed space: 0B
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

`rm -f` borra el contenedor `web` aunque esté corriendo, y `container prune -f` borra todos los que ya terminaron, entre ellos el de `hello-world`. Tu lista de identificadores va a ser otra. `docker ps -a` ya no muestra ninguno.

Las imágenes pueden quedar: sin contenedores no ocupan memoria ni puertos, y solo pesan en disco (unos 120 MB). La próxima vez que corras `httpd:2.4` no se vuelve a bajar. Se ven con `sudo docker images`:

```text
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
httpd         2.4       caeb353ae229   4 days ago     117MB
hello-world   latest    e2ac70e7319a   7 months ago   10.1kB
```

Si preferís liberar el espacio, `sudo docker rmi httpd:2.4 hello-world`.

### Deshabilitar y detener el servicio

Para que Docker no arranque con la VM hay que deshabilitar y detener las tres unidades: `docker.service`, `docker.socket` y `containerd.service`, que el servicio de Docker pide al arrancar. Si dejaras habilitado el socket, `systemd` lo abriría al iniciar la VM y el primer `docker` lo volvería a poner en marcha.

```bash
sudo systemctl disable --now docker.service docker.socket containerd.service
systemctl is-enabled docker docker.socket containerd
systemctl is-active docker docker.socket containerd
```

```text
Synchronizing state of docker.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable docker
Removed '/etc/systemd/system/multi-user.target.wants/docker.service'.
Removed '/etc/systemd/system/sockets.target.wants/docker.socket'.
Disabling 'docker.service', but its triggering units are still active:
docker.socket
Removed '/etc/systemd/system/multi-user.target.wants/containerd.service'.
disabled
disabled
disabled
inactive
inactive
inactive
```

El aviso `its triggering units are still active` aparece porque el socket se detiene después del servicio, y no es un error. Se ve que las tres quedan `disabled` e `inactive`.

Con el servicio parado, el cliente no tiene con quién hablar:

```bash
sudo docker ps
```

```text
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Cuando quieras volver a usar Docker, arrancalo sin habilitarlo, así se apaga con el próximo reinicio de la VM. Al arrancar `docker`, systemd arranca también el socket y `containerd`:

```bash
sudo systemctl start docker
sudo docker ps
```

```text
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Para dejarlo parado de nuevo: `sudo systemctl stop docker docker.socket containerd`.

### Quitar la regla de reenvío

En la anfitriona, por la terminal:

```bash
VBoxManage controlvm Lab2 natpf1 delete web
VBoxManage showvminfo Lab2 --machinereadable | grep Forwarding
```

```text
Forwarding(0)="Rule 1,tcp,,2222,,22"
```

Tiene que quedar solo la regla del SSH. Por la interfaz gráfica es lo mismo que al agregarla: **Configuración** → **Red** → **Adaptador 1** → **Reenvío de puertos**, seleccionás la regla `web` y la borrás con el botón de quitar. No toques la regla `Rule 1` del SSH: sin ella no podés entrar a la VM.

Con la regla quitada, `http://localhost:8080` ya no responde en el navegador.

## 6. Comprobar que no arranca solo (opcional)

Reiniciá la VM y entrá de nuevo por SSH cuando vuelva:

```bash
sudo reboot
```

```bash
ssh -p 2222 cristian@localhost
systemctl is-active docker docker.socket containerd
```

```text
inactive
inactive
inactive
```

Docker sigue instalado (`docker --version` anda) y no está corriendo. El cliente todavía no puede hablarle: `sudo docker ps` da el mismo mensaje de antes hasta que hagas `sudo systemctl start docker`.

## Resumen del laboratorio

- Docker se instala con `apt install docker.io`. El paquete deja tres unidades habilitadas y activas: `docker.service`, `docker.socket` y `containerd.service`.
- El socket es de `root` y del grupo `docker`: por eso usamos `sudo docker` y no agregamos el usuario al grupo.
- `hello-world` prueba la instalación. `sudo docker run -d --name web -p 8080:80 httpd:2.4` levanta un servidor web en una línea.
- Para llegar desde la anfitriona hace falta una regla de reenvío de VirtualBox, como la del SSH.
- Para que Docker no arranque con la VM se deshabilitan las tres unidades. Para usarlo de nuevo, `sudo systemctl start docker`.

## Enlaces útiles y referencias

- Ayuda: `man docker`, `man docker-run`, `man systemctl`. En línea (en inglés): [documentación de Docker](https://docs.docker.com/) y [`docker run`](https://docs.docker.com/reference/cli/docker/container/run/).
- [Imagen oficial `httpd` en Docker Hub](https://hub.docker.com/_/httpd) y [`hello-world`](https://hub.docker.com/_/hello-world).
- Clase 20: [presentación](https://linux.idepba.com.ar/clase20.html).
- Anterior: [Laboratorio 18 - Resolución de nombres y DNS](../lab18/lab18.md).
- Siguiente: [Laboratorio 19.2 - Contenedores con Podman en Rocky Linux](lab19.2.md), el mismo recorrido con Podman.

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
