# Laboratorio 19.2 - Contenedores con Podman en Rocky Linux

## Objetivo

- Instalar Podman en la VM Rocky y comprobar que quedó bien con la imagen `hello-world`.
- Levantar un servidor web Apache con una sola línea y verlo con `curl`.
- Comprobar que los procesos del contenedor son de tu usuario y no de `root`.
- Abrirlo desde el navegador de la anfitriona con una regla de reenvío de puertos de VirtualBox y un puerto abierto en el firewall.
- Dejar la VM como estaba: sin contenedores y con Podman instalado, sin nada que arranque solo.

### Punto de partida

- La VM Rocky Linux, con la cuenta `usuario` (contraseña `linux410`) y acceso por SSH en el puerto 2223.
- Conexión a Internet en la VM, para bajar los paquetes y las imágenes (unos 23 MB de paquetes y 120 MB de imágenes).

No hace falta haber hecho otros laboratorios. Los pasos funcionan aunque Podman ya esté instalado. La teoría está en la [clase 20](https://linux.idepba.com.ar/clase20.html). El mismo recorrido con Docker, en la VM Debian, está en el [Laboratorio 19.1](lab19.1.md).

> [!IMPORTANT]
> **¿No tenés la VM de Rocky?** Descargá `Lab_Rocky.ova` y `Lab_Rocky.ova.sha256` de [linux-files.idep.atepba.org.ar](https://linux-files.idep.atepba.org.ar/) y seguí los pasos 2 a 4 del [Laboratorio 10.2](../lab10/lab10.2.md): comprobar la descarga, importar la VM e iniciarla. Hacen falta unos 6 GB libres en la anfitriona. Si la VM ya tiene reglas de reenvío de otros laboratorios, no las toques.

> [!NOTE]
> Los identificadores de contenedor, los nombres al azar, las fechas, los PID y los tiempos de tus salidas van a ser otros. Los comandos de `podman` se escriben sin `sudo`: Podman se usa como usuario común. `sudo` aparece solo para instalar y para el firewall.

### Dónde se trabaja

- En la Rocky: una terminal con `ssh -p 2223 usuario@localhost`. El prompt dice `[usuario@localhost ~]$`.
- En la anfitriona: la terminal de tu equipo (PowerShell en Windows) y el navegador. Solo se usan en los pasos que lo indican.

> [!WARNING]
> Dejá abierta la terminal de la Rocky durante todo el laboratorio. Con Podman sin root, los contenedores viven dentro de la sesión de tu usuario: cuando se cierra la última sesión, el sistema detiene el gestor de tu usuario y los contenedores se apagan con él. Si te pasa, vas a ver el contenedor en `Exited (0)` y alcanza con arrancarlo de nuevo con `podman start web`.

## 1. Instalar Podman

En Debian, Docker necesitaba un servicio que corriera como `root`. Podman no tiene ese servicio: cada usuario lo ejecuta con sus propios permisos y no hay nada que arrancar. A eso se le dice modo *rootless*. Está en los repositorios de Rocky:

```bash
sudo dnf install -y podman
podman --version
```

La instalación baja 21 paquetes (unos 23 MB), entre ellos `crun`, que es el que crea los contenedores, y `conmon`, un programa chico que vigila cada contenedor. Al final de la salida se ve el resumen:

```text
Resumen de la transacción
================================================================================
Instalar  21 Paquetes

Tamaño total de la descarga: 23 M
Tamaño instalado: 77 M
...
¡Listo!
```

```text
podman version 5.8.2
```

La versión depende de las actualizaciones de Rocky. El paquete no deja ningún servicio habilitado: no hay nada que arrancar. Lo comprobamos al final.

## 2. El primer contenedor: `hello-world`

```bash
podman run --name hola docker.io/library/hello-world
```

```text
Trying to pull docker.io/library/hello-world:latest...
Getting image source signatures
Copying blob sha256:4f55086f7dd096d48b0e49be066971a8ed996521c2e190aa21b2435a847198b4
Copying config sha256:e2ac70e7319a02c5a477f5825259bd118b94e8b02c279c67afa63adab6d8685b
Writing manifest to image destination

Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

Se recortó el texto que sigue al mensaje, que explica los pasos y ofrece más ejemplos. Es la misma imagen de Docker Hub que usamos en el Laboratorio 19.1: las imágenes siguen el estándar OCI y sirven en Docker y en Podman. El texto habla de Docker porque lo escribió el autor de la imagen, y el contenedor lo creó Podman. Si volvés a correr el comando, ya no baja nada, porque la imagen quedó guardada.

Con Podman escribimos el nombre completo de la imagen, `docker.io/library/hello-world`, con el registro al principio. Docker completa el registro por su cuenta; Podman, con un nombre corto, puede preguntarte de dónde bajarla. Con el nombre completo sabemos de dónde viene la imagen.

Con `--name hola` el contenedor tiene nombre propio, y después lo borramos fácil. Si repetís el comando sin borrarlo, Podman dice que el nombre `hola` ya está en uso: borralo con `podman rm hola` y volvé a correrlo.

Un contenedor que terminó no desaparece. Con `-a` se ven también los que ya no corren:

```bash
podman ps -a
podman images
```

```text
CONTAINER ID  IMAGE                                 COMMAND     CREATED                 STATUS                   PORTS       NAMES
195e49ffb865  docker.io/library/hello-world:latest  /hello      Less than a second ago  Exited (0) 1 second ago              hola
REPOSITORY                     TAG         IMAGE ID      CREATED       SIZE
docker.io/library/hello-world  latest      e2ac70e7319a  7 months ago  25.5 kB
```

El contenedor está `Exited (0)`: el programa imprimió el mensaje y terminó sin error. La imagen pesa 25,5 kB, porque el programa es un único archivo.

## 3. Un servidor web en una línea

Apache viene en la imagen oficial `httpd`, versión `2.4`:

```bash
podman run -d --name web -p 8080:80 docker.io/library/httpd:2.4
```

```text
Trying to pull docker.io/library/httpd:2.4...
Getting image source signatures
Copying blob sha256:36f27ea25a129a54510ed2f2a330fab7a5dcaf941c0ef11ce7923bb92c3003b0
...
Copying config sha256:caeb353ae2292529c3988402ec4da0faf6392323b2383f0985a895a0f47912ad
Writing manifest to image destination
b70219093e14e6b79bff1c0d8ab24c2d72b91b707a8f4a0b6b8dd59d53189ab0
```

Se recortaron las líneas de las capas que se descargan. La última línea es el identificador completo del contenedor. Lo que significa cada opción:

- `-d` lo deja corriendo en segundo plano y devuelve la terminal.
- `--name web` le da un nombre propio.
- `-p 8080:80` publica un puerto: lo que llegue al puerto 8080 de la VM va al puerto 80 del contenedor, donde escucha Apache. Va primero el de la VM y después el del contenedor.
- `docker.io/library/httpd:2.4` es la imagen, con el registro y la versión.

No instalamos Apache ni tocamos su configuración. Comprobamos que está corriendo y le pedimos la página:

```bash
podman ps
curl http://localhost:8080
```

```text
CONTAINER ID  IMAGE                        COMMAND           CREATED                 STATUS                 PORTS                 NAMES
b70219093e14  docker.io/library/httpd:2.4  httpd-foreground  Less than a second ago  Up Less than a second  0.0.0.0:8080->80/tcp  web
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

`0.0.0.0:8080->80/tcp` es el puerto publicado: escucha en todas las direcciones de la VM. La página dice `It works!`. Lo que Apache escribe en su registro se ve con `podman logs`:

```bash
podman logs web
```

```text
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.0.2.15. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 10.0.2.15. Set the 'ServerName' directive globally to suppress this message
[Sun Nov 15 23:31:24.841903 2026] [mpm_event:notice] [pid 1:tid 1] AH00489: Apache/2.4.71 (Unix) configured -- resuming normal operations
[Sun Nov 15 23:31:24.847063 2026] [core:notice] [pid 1:tid 1] AH00094: Command line: 'httpd -D FOREGROUND'
fd17:625c:f037:2:a00:27ff:fe8c:7786 - - [15/Nov/2026:23:31:24 +0000] "GET / HTTP/1.1" 200 191
```

La última línea es el pedido de `curl`, que llegó desde la propia VM por IPv6 (la dirección larga es la de la VM). El aviso `AH00558` es normal: la imagen no define un nombre de servidor y Apache lo informa, pero funciona igual. Las líneas salen por dos salidas distintas, así que su orden puede cambiar.

Si algo no da lo que se espera:

- `Failed to bind port 8080 (Address already in use)`: el 8080 de la VM ya lo usa otro contenedor u otro programa. Buscalo con `podman ps` y `ss -tln`, y borralo, o elegí otro puerto, por ejemplo `-p 8082:80`. El contenedor queda creado sin arrancar; borralo con `podman rm -f web`.
- `the container name "web" is already in use`: ya hay un contenedor con ese nombre, quizás de un intento anterior. Borralo con `podman rm -f web` y repetí el `run`.
- `curl` dice `Connection refused` o `Recv failure` justo después del `run`: Apache tarda un segundo en arrancar. Repetí el `curl`.

### ¿De quién son los procesos?

Los procesos del contenedor son procesos de la VM, y se ven con `ps`:

```bash
ps -o user,pid,cmd -C httpd
```

```text
USER         PID CMD
usuario     2243 httpd -DFOREGROUND
100032      2251 httpd -DFOREGROUND
100032      2252 httpd -DFOREGROUND
100032      2253 httpd -DFOREGROUND
```

Ninguno es de `root`. El primero es de `usuario`, y los demás figuran con un número, `100032`. Dentro del contenedor, Apache trabaja con el usuario `www-data` y Podman lo traduce a un número de la lista de identificadores que el sistema le reservó a `usuario` (`grep usuario /etc/subuid` muestra el rango, que empieza en 100000). Con `podman top web user huser` se ven los dos nombres: el de adentro y el número de la VM. Por eso el modo rootless es más seguro: si alguien escapara del contenedor, sería un usuario sin privilegios.

### El puerto 80 no se puede

Como no somos `root`, hay un límite: los puertos menores de 1024 están reservados. Probalo:

```bash
podman run -d --name web80 -p 80:80 docker.io/library/httpd:2.4
podman rm -f web80
```

```text
Error: pasta failed with exit code 1:
Failed to bind port 80 (Permission denied) for option '-t 80-80:80-80'

web80
```

`pasta` es el programa que Podman usa para conectar el contenedor con la red de la VM, y no pudo abrir el puerto 80 sin ser `root`. El contenedor quedó creado pero sin arrancar, por eso el segundo comando lo borra. Por eso publicamos el 8080 y no el 80.

## 4. Abrirlo desde el navegador de la anfitriona

El `curl` anduvo porque corrió dentro de la VM. El navegador de tu equipo está afuera, y la VM usa un adaptador de red en NAT, igual que en el [Laboratorio 13.2](../lab13/lab13.2.md): desde la anfitriona no se llega al puerto 8080 de la VM sin una regla de reenvío. Acá hay además un segundo obstáculo, el firewall de Rocky. El camino es:

```text
Navegador: localhost:8081  →  VirtualBox NAT  →  VM:8080 (firewalld)  →  Podman  →  contenedor:80
```

Usamos el 8081 en la anfitriona para que no choque con el 8080 del Laboratorio 19.1 si tenés las dos VM encendidas.

### La regla de reenvío

Por la interfaz gráfica, con la VM **apagada** (`sudo poweroff`), o por la terminal si no querés apagarla.

1. En VirtualBox, seleccioná `Lab_Rocky` y abrí **Configuración**.
2. Entrá en **Red** → **Adaptador 1** → **Reenvío de puertos**. Ya está la regla del puerto 2223 para SSH.
3. Agregá una regla nueva:

| Nombre | Protocolo | IP Anfitrión | Puerto anfitrión | IP invitado | Puerto invitado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| web | TCP |  | 8081 |  | 8080 |

Los campos **IP anfitrión** e **IP invitado** quedan vacíos. Aceptá los cambios y arrancá la VM.

Por la terminal de la anfitriona, con la VM encendida (si tu VM no se llama `Lab_Rocky`, cambiá el nombre):

```bash
VBoxManage controlvm Lab_Rocky natpf1 "web,tcp,,8081,,8080"
VBoxManage showvminfo Lab_Rocky --machinereadable | grep Forwarding
```

```text
Forwarding(0)="Rule 1,tcp,,2223,,22"
Forwarding(1)="syslog,tcp,,2514,,514"
Forwarding(2)="web,tcp,,8081,,8080"
```

La regla `syslog` está solo si hiciste el Laboratorio 13.2. En Windows, si `VBoxManage` no se reconoce, está en `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`. Si te cerraste sin querer la terminal de la Rocky o la VM se reinició, volvé a entrar por SSH y arrancá el contenedor con `podman start web`.

### El firewall bloquea

Con la regla puesta, probá desde la terminal de la anfitriona:

```bash
curl --max-time 6 http://localhost:8081
```

```text
curl: (28) Operation timed out after 6002 milliseconds with 0 bytes received
```

(En PowerShell, `curl.exe --max-time 6 http://localhost:8081`.) No contesta: la conexión llega a la VM, pero `firewalld` descarta lo que no está permitido, y el 8080 no está. Lo mismo pasaría en el navegador, que se queda cargando. Lo vemos con `firewall-cmd`, en la Rocky:

```bash
sudo firewall-cmd --list-ports
```

La salida está vacía: no hay ningún puerto abierto, solo los servicios `cockpit`, `dhcpv6-client` y `ssh`. Abrimos el 8080:

```bash
sudo firewall-cmd --add-port=8080/tcp
sudo firewall-cmd --list-ports
```

```text
success
8080/tcp
```

Sin `--permanent`, el puerto queda abierto solo hasta el próximo reinicio de la VM o de `firewalld`. Para un laboratorio es lo que queremos: no queda una regla olvidada. El firewall se ve completo en la clase 22.

### Probar

En la anfitriona, abrí el navegador en `http://localhost:8081`. Tiene que mostrar el mensaje `It works!`:

![Página «It works!» de Apache vista desde el navegador de la anfitriona en http://localhost:8081](../img/lab19/web-podman.png)

Si querés probarlo también por la terminal de la anfitriona: `curl http://localhost:8081`.

Si el navegador no conecta:

- Mirá que el contenedor siga corriendo (`podman ps` en la VM) y que `curl http://localhost:8080` ande dentro de la VM.
- Mirá que el puerto esté abierto (`sudo firewall-cmd --list-ports` tiene que decir `8080/tcp`) y que la regla exista (`VBoxManage showvminfo Lab_Rocky --machinereadable | grep Forwarding`).
- Si el 8081 de la anfitriona ya está ocupado por otro programa, VirtualBox no puede abrirlo. Usá otro puerto de anfitrión, por ejemplo 8082, con la regla `web,tcp,,8082,,8080`.
- Probá con `http://127.0.0.1:8081`, por si `localhost` apunta a IPv6.

### El pedido en el registro

Volvé a la VM y mirá qué anotó Apache de las visitas del navegador:

```bash
podman logs web | grep GET
```

```text
fd17:625c:f037:2:a00:27ff:fe8c:7786 - - [15/Nov/2026:23:31:24 +0000] "GET / HTTP/1.1" 200 191
10.0.2.2 - - [15/Nov/2026:23:31:32 +0000] "GET / HTTP/1.1" 200 191
10.0.2.2 - - [15/Nov/2026:23:31:32 +0000] "GET /favicon.ico HTTP/1.1" 404 236
```

La primera línea es la del `curl` de la VM. Las demás son de la anfitriona: llegan desde `10.0.2.2`, que es la anfitriona vista desde la red NAT de VirtualBox. El `404` de `/favicon.ico` es el navegador pidiendo el ícono de la pestaña, que Apache no tiene. En tu salida va a haber una línea por cada vez que abriste o recargaste la página.

## 5. Dejar la VM como estaba

Podman se queda instalado, pero sin contenedores, sin puertos abiertos y sin nada que arranque solo.

### Borrar los contenedores

```bash
podman rm -f web hola
podman ps -a
```

```text
hola
web
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
```

`rm -f` borra los contenedores aunque estén corriendo. `podman ps -a` ya no muestra ninguno. Si hiciste el paso del puerto 80 y no borraste `web80`, agregalo a la lista.

Las imágenes pueden quedar: sin contenedores no ocupan memoria ni puertos, solo disco (unos 120 MB), y la próxima vez no hay que bajarlas otra vez. Se ven con `podman images`. Si preferís liberar el espacio: `podman rmi docker.io/library/httpd:2.4 docker.io/library/hello-world`.

### Cerrar el puerto

```bash
sudo firewall-cmd --remove-port=8080/tcp
sudo firewall-cmd --list-ports
```

```text
success

```

La segunda salida es una línea vacía: no queda ningún puerto abierto. Si reiniciás la VM, el puerto se cierra solo, pero conviene cerrarlo apenas terminás.

### Quitar la regla de reenvío

En la anfitriona, por la terminal:

```bash
VBoxManage controlvm Lab_Rocky natpf1 delete web
VBoxManage showvminfo Lab_Rocky --machinereadable | grep Forwarding
```

```text
Forwarding(0)="Rule 1,tcp,,2223,,22"
Forwarding(1)="syslog,tcp,,2514,,514"
```

Tiene que quedar la regla del SSH (y `syslog`, si la tenías). Por la interfaz gráfica es lo mismo que al agregarla: **Configuración** → **Red** → **Adaptador 1** → **Reenvío de puertos**, seleccionás la regla `web` y la borrás con el botón de quitar. No toques la regla `Rule 1` del SSH: sin ella no podés entrar a la VM.

### Comprobar que nada arranca solo

```bash
systemctl list-unit-files 'podman*'
```

```text
UNIT FILE                      STATE    PRESET
podman-auto-update.service     disabled disabled
podman-clean-transient.service disabled disabled
podman-kube@.service           disabled disabled
podman-restart.service         disabled disabled
podman.service                 disabled disabled
podman.socket                  disabled disabled
podman-auto-update.timer       disabled disabled

7 unit files listed.
```

Todas están `disabled`. Son servicios opcionales que no usamos: por ejemplo, `podman-restart.service` sirve para volver a arrancar contenedores al iniciar el equipo. Como nadie los habilitó, al reiniciar la VM no arranca ningún contenedor.

## 6. Comprobar que no arranca solo (opcional)

Reiniciá la VM y entrá de nuevo por SSH cuando vuelva:

```bash
sudo reboot
```

```bash
ssh -p 2223 usuario@localhost
podman ps -a
sudo firewall-cmd --list-ports
systemctl list-units 'podman*' --all --no-legend
```

```text
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
```

Las tres comprobaciones salen vacías: no hay contenedores, el puerto 8080 está cerrado en `firewalld` y ninguna unidad del sistema se puso en marcha. Podman sigue instalado (`podman --version` anda) y las imágenes siguen guardadas.

## Preguntas

1. ¿Por qué Podman no necesita un servicio como `docker.service`?
2. ¿Por qué `ps` muestra procesos de `usuario` y no de `root`, si Apache corre en un contenedor?
3. ¿Qué hubiera pasado en el paso 4 si no abrías el 8080 en `firewalld`? ¿Y si lo abrías con `--permanent`?
4. ¿Por qué falló `-p 80:80` y anduvo `-p 8080:80`?

## Resumen del laboratorio

- Podman se instala con `dnf install podman`. No tiene un servicio central: lo ejecuta cada usuario, sin `root` (rootless), y el paquete no deja nada habilitado.
- Con Podman escribimos el nombre completo de la imagen, con el registro (`docker.io/library/httpd:2.4`). La imagen es la misma que usa Docker, porque ambos siguen la OCI.
- `podman run -d --name web -p 8080:80 imagen` levanta un servicio en una línea. `podman ps`, `podman logs`, `podman rm -f` son los mismos comandos que en Docker.
- Los procesos del contenedor se ven con `ps` y son de tu usuario. Sin ser `root` no se pueden publicar puertos menores de 1024.
- Para llegar desde la anfitriona hacen falta dos cosas: la regla de reenvío de VirtualBox y el puerto abierto en `firewalld`. Sin `--permanent`, el puerto se cierra con el próximo reinicio.
- Los contenedores sin root se apagan cuando se cierra la última sesión del usuario.

## Enlaces útiles y referencias

- Ayuda: `man podman`, `man podman-run`, `man firewall-cmd`. En línea (en inglés): [documentación de Podman](https://docs.podman.io/en/latest/) y [`podman run`](https://docs.podman.io/en/latest/markdown/podman-run.1.html).
- [Imagen oficial `httpd` en Docker Hub](https://hub.docker.com/_/httpd) y [`hello-world`](https://hub.docker.com/_/hello-world).
- Clase 20: [presentación](https://linux.idepba.com.ar/clase20.html).
- Anterior: [Laboratorio 19.1 - Contenedores con Docker en Debian](lab19.1.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
