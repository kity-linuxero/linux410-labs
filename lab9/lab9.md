# Laboratorio 9 - Procesos y servicios

## Objetivo

- Ver qué procesos corren en el servidor y con qué usuario.
- Suspender un trabajo, dejarlo seguir en segundo plano y recuperarlo.
- Encontrar un proceso que consume CPU, obtener su PID y terminarlo.
- Consultar, detener, iniciar, deshabilitar y habilitar un servicio con `systemctl`.
- Leer el registro de un servicio con `journalctl`.

### Punto de partida

Usamos la VM Debian 13 del curso y la cuenta administradora con `sudo`, por ejemplo `cristian`. **Alcanza con tener la VM instalada y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md).** No se usan Ana ni Bruno.

Trabajaremos con dos terminales, las dos con tu usuario habitual:

| Terminal | Uso |
| --- | --- |
| **A** | Lanzar procesos, como si fuera la sesión de otra persona |
| **B** | Buscar esos procesos, terminarlos y administrar el servicio |

> [!NOTE]
> Reemplazá `cristian` por tu usuario habitual. Los comandos de SSH usan el reenvío del curso, puerto 2222 del anfitrión hacia SSH de la VM. Los números de PID de los ejemplos van a ser otros en tu VM.

> [!IMPORTANT]
> Antes de cada bloque, fijate en qué terminal va. El servicio `systemd-timesyncd` tiene que quedar funcionando y habilitado; lo comprobamos al final.

## 0. Preparación

### 1. Abrí las dos terminales

**Terminal A — desde la máquina anfitriona:**

```bash
ssh -p 2222 cristian@localhost
```

**Terminal B — desde la máquina anfitriona:**

```bash
ssh -p 2222 cristian@localhost
```

En cada una, comprobá que estás en la VM:

```bash
hostname
whoami
```

Tiene que aparecer `lab2-vm` (o el nombre que le hayas dado) y tu usuario.

### 2. Instalá htop y psmisc

**Terminal B.**

```bash
sudo apt update
sudo apt install htop psmisc
```

`apt` muestra un resumen de lo que va a instalar y pregunta `Continue? [S/n]`. Respondé `S` y `Enter`. Si alguno de los paquetes ya estaba instalado, avisa que «ya está en su versión más reciente».

`htop` muestra los procesos y su consumo de forma más cómoda que `top`. `psmisc` trae `pstree` y `killall`, que Debian no instala por omisión. `apt` lo vemos en la clase 11; por ahora alcanza con saber que instala programas desde los repositorios de Debian.

Comprobá que los tres comandos quedaron disponibles:

```bash
command -v htop pstree killall
```

Resultado esperado:

```text
/usr/bin/htop
/usr/bin/pstree
/usr/bin/killall
```

Si falta alguno, repetí la instalación y revisá el mensaje de error de `apt`.

## 1. Ubicarse entre los procesos

### 1. El primer proceso del sistema

**Terminal A.**

```bash
ps -p 1
```

Resultado esperado:

```text
    PID TTY          TIME CMD
      1 ?        00:00:00 systemd
```

El PID 1 es systemd, como vimos en la clase 4. El `?` en TTY indica que no está asociado a ninguna terminal.

### 2. Tu shell y su camino hasta PID 1

**Terminal A.**

```bash
echo $$
pstree -sp $$
```

`$$` es el PID de la shell en la que estás escribiendo, y `pstree -sp` muestra el camino desde PID 1 hasta ella.

Ejemplo de salida:

```text
1216
systemd(1)───sshd(714)───sshd-session(1209)───sshd-session(1215)───bash(1216)───pstree(1240)
```

Se lee de izquierda a derecha. systemd arrancó el servicio SSH (`sshd`), que creó una sesión para tu conexión, y esa sesión abrió tu `bash`. La conexión aparece dos veces porque una parte corre como root y otra con tu usuario. Al final está el propio `pstree`, que también es un proceso.

Repetí `echo $$` en la **terminal B**. Vas a ver otro número, porque cada terminal tiene su propia shell.

### 3. Tus procesos y los de todo el sistema

**Terminal A.**

```bash
ps -u $USER
```

Ejemplo de salida:

```text
    PID TTY          TIME CMD
    794 ?        00:00:00 systemd
    796 ?        00:00:00 (sd-pam)
   1215 ?        00:00:00 sshd-session
   1216 pts/2    00:00:00 bash
   1227 ?        00:00:00 sshd-session
   1228 pts/3    00:00:00 bash
   1233 pts/2    00:00:00 ps
```

Aparecen las dos shells, una por terminal (`pts/2` y `pts/3` en el ejemplo), y el propio `ps`. Puede haber más líneas si tenés otras sesiones abiertas.

Ahora todos los procesos, con usuario y PID:

```bash
ps -ef | head
```

Ejemplo de salida:

```text
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 22:39 ?        00:00:00 /sbin/init
root           2       0  0 22:39 ?        00:00:00 [kthreadd]
root           3       2  0 22:39 ?        00:00:00 [pool_workqueue_release]
...
```

Las columnas que más vamos a usar son UID (usuario), PID y CMD (comando). Los nombres entre corchetes son hilos del kernel.

## 2. Primer y segundo plano

### 1. Un trabajo en segundo plano

**Terminal A.**

```bash
sleep 300 &
jobs -l
```

Ejemplo de salida:

```text
[1] 1234
[1]+  1234 Ejecutando              sleep 300 &
```

`[1]` es el número de trabajo de esta shell y `1234` es el PID. Con `&` el prompt vuelve enseguida mientras `sleep` sigue corriendo.

### 2. Suspender con Ctrl+Z

**Terminal A.** Lanzá otro `sleep`, esta vez en primer plano:

```bash
sleep 400
```

La terminal queda ocupada. Presioná `Ctrl+Z`:

```text
^Z
[2]+  Detenido                sleep 400
```

Volvió el prompt, pero el proceso quedó **suspendido**. Comprobalo:

```bash
jobs -l
ps -o pid,stat,comm -C sleep
```

Ejemplo de salida:

```text
[1]-  1234 Ejecutando              sleep 300 &
[2]+  1235 Parado                  sleep 400

    PID STAT COMMAND
   1234 S    sleep
   1235 T    sleep
```

El primero está esperando (`S`) y el segundo, detenido (`T`). Es lo que pasa cuando alguien presiona `Ctrl+Z` en un editor y cree que lo cerró: el programa sigue ahí.

### 3. Los trabajos son de cada shell

**Terminal B.**

```bash
jobs
pgrep -a sleep
```

Ejemplo de salida:

```text
1234 sleep 300
1235 sleep 400
```

En B, `jobs` no muestra nada, porque los trabajos pertenecen a la shell de A. `pgrep -a` los encuentra igual, porque busca entre todos los procesos del sistema.

### 4. Que siga en segundo plano con bg

`sleep 400` está suspendido. Con `bg` sigue corriendo en segundo plano, como si lo hubieras lanzado con `&`.

**Terminal A.**

```bash
bg %2
jobs -l
ps -o pid,stat,comm -C sleep
```

Ejemplo de salida:

```text
[2]+ sleep 400 &

[1]-  1234 Ejecutando              sleep 300 &
[2]+  1235 Ejecutando              sleep 400 &

    PID STAT COMMAND
   1234 S    sleep
   1235 S    sleep
```

Los dos trabajos están corriendo otra vez y la terminal quedó libre. Esto sirve cuando lanzaste algo largo sin `&`: con `Ctrl+Z` lo suspendés y con `bg` lo dejás seguir sin perder la terminal.

### 5. Traer al primer plano y cortar

**Terminal A.**

```bash
fg %2
```

`sleep 400` vuelve a ocupar la terminal. Presioná `Ctrl+C` para interrumpirlo y después:

```bash
jobs
fg %1
```

Presioná `Ctrl+C` otra vez y comprobá que no quedó ninguno:

```bash
jobs
```

No tiene que aparecer nada.

## 3. Encontrar y terminar un proceso que consume CPU

### 1. Lanzá un consumo de CPU

**Terminal A.**

```bash
yes > /dev/null
```

`yes` repite una letra sin parar y la redirección a `/dev/null` descarta todo lo que escribe. La terminal A queda ocupada. **Dejala así** y pasá a B: vamos a tratarlo como un proceso de otra sesión, que no podés cortar con `Ctrl+C`.

### 2. Miralo con top

**Terminal B.**

```bash
top
```

Ejemplo de las primeras líneas:

```text
top - 22:57:40 up 18 min,  2 users,  load average: 0,08, 0,02, 0,01
Tareas: 103 total,   3 ejecutar,  100 hibernar,    0 detener,    0 zombie
%Cpu(s): 20,0 us, 60,0 sy,  0,0 ni,  0,0 id,  0,0 wa,  0,0 hi, 20,0 si,  0,0 st
MiB Mem :    948,6 total,    729,6 libre,    236,1 usado,    105,0 búf/caché
MiB Intercambio:   1005,0 total,   1005,0 libre,      0,0 usado.    712,5 dispon

    PID USUARIO   PR  NI    VIRT    RES    SHR S  %CPU  %MEM     HORA+ ORDEN
   1238 cristian  20   0    5800   2248   2128 R  91,7   0,2   0:03.24 yes
```

`yes` aparece primero, con cerca de 100 % de CPU y estado `R`. En `%Cpu(s)`, `id` (tiempo ocioso) bajó a 0, porque la VM tiene una sola CPU y `yes` la ocupa entera. Anotá el PID y el USUARIO.

Dejá `top` abierto alrededor de un minuto y mirá `load average`. El primer valor sube de a poco hacia 1 y al minuto ronda `0,6` o `0,7`. Los otros dos suben más lento porque promedian 5 y 15 minutos. Con una CPU, una carga de 1 quiere decir que está ocupada todo el tiempo. Salí con `q`.

### 3. Miralo con htop

**Terminal B.**

```bash
htop
```

`htop` ordena por CPU, así que `yes` aparece arriba de todo y la barra `CPU` está llena. Con `F3` podés buscarlo por nombre: escribí `yes` y `Enter`, y la línea queda seleccionada.

Salí con `q` o `F10`. No termines el proceso desde `htop`: lo vamos a hacer con `kill`.

### 4. Obtené el PID

**Terminal B.**

```bash
pgrep -a yes
ps -ef | grep yes
```

Ejemplo de salida:

```text
1238 yes

cristian    1238    1216 98 22:57 pts/2    00:00:03 yes
cristian    1243    1228  0 22:57 pts/3    00:00:00 grep yes
```

Los dos muestran el mismo PID. `ps -ef | grep` agrega usuario y proceso padre, y también muestra la línea del propio `grep`, que no hay que terminar. `pgrep -a` no la muestra.

### 5. Terminalo con kill

**Terminal B.** Usá el PID que obtuviste:

```bash
kill 1238
```

Si funcionó, `kill` no muestra nada. En la **terminal A** aparece:

```text
Terminado
```

y vuelve el prompt. Comprobalo desde B:

```bash
pgrep -a yes
echo $?
```

Resultado esperado:

```text
1
```

`pgrep` no encontró nada y devolvió 1, así que el proceso terminó.

> [!NOTE]
> Si `kill` no alcanza, el último recurso es `kill -9 PID`. Acá no hizo falta: `kill` sin opciones le pide al programa que termine y le deja cerrar ordenadamente.

## 4. Terminar varios procesos por nombre

### 1. Lanzá tres procesos iguales

**Terminal B.**

```bash
sleep 1000 &
sleep 1000 &
sleep 1000 &
pgrep -a sleep
```

Ejemplo de salida:

```text
1247 sleep 1000
1248 sleep 1000
1249 sleep 1000
```

### 2. Terminalos con killall

**Terminal B.**

```bash
killall sleep
```

`killall` no muestra nada, y la shell avisa que los tres trabajos terminaron:

```text
[1]   Terminado               sleep 1000
[2]-  Terminado               sleep 1000
[3]+  Terminado               sleep 1000
```

Comprobalo:

```bash
pgrep -a sleep
jobs
```

Ninguno de los dos muestra nada.

`killall` actúa sobre **todos** los procesos con ese nombre que te pertenecen. Antes de usarlo, conviene revisar con `pgrep -a` a cuáles va a alcanzar.

## 5. Quién puede terminar qué

### 1. Un proceso de root

**Terminal B.**

```bash
sudo -b sleep 600
ps -o user,pid,comm -C sleep
```

`sudo -b` lanza el comando como root y en segundo plano. Ejemplo de salida:

```text
USER         PID COMMAND
root        1109 sleep
```

### 2. Intentá terminarlo sin sudo

**Terminal B.** Con el PID de tu salida:

```bash
kill 1109
```

Resultado esperado:

```text
-bash: kill: (1109) - Operación no permitida
```

Tu usuario solo puede terminar sus propios procesos. Es la misma idea de identidad que vimos con los permisos de archivos en la clase 9.

### 3. Terminalo con sudo

```bash
sudo kill 1109
pgrep -a sleep
```

`pgrep` ya no muestra nada.

## 6. Administrar un servicio: systemd-timesyncd

`systemd-timesyncd` mantiene en hora el reloj de la VM consultando servidores de tiempo. En la clase 4 lo vimos de forma indirecta con `timedatectl`. Detenerlo unos minutos no afecta a nada.

### 1. Consultá su estado

**Terminal B.**

```bash
systemctl status systemd-timesyncd
```

Ejemplo de salida:

```text
● systemd-timesyncd.service - Network Time Synchronization
     Loaded: loaded (/usr/lib/systemd/system/systemd-timesyncd.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-09-27 22:39:23 -03; 9min ago
   Main PID: 304 (systemd-timesyn)
     Status: "Contacted time server 170.210.222.2:123 (2.debian.pool.ntp.org)."
     CGroup: /system.slice/systemd-timesyncd.service
             └─304 /usr/lib/systemd/systemd-timesyncd
```

Si la salida no entra en la pantalla, salí con `q`.

En la línea `Loaded`, `enabled` indica que arranca con el sistema. `active (running)` quiere decir que está corriendo ahora, y `Main PID` es su proceso principal.

Al pie puede aparecer un aviso de que no se pudieron abrir algunos archivos del registro. Eso se resuelve en el paso 5 con `sudo`.

Las dos preguntas, por separado:

```bash
systemctl is-active systemd-timesyncd
systemctl is-enabled systemd-timesyncd
```

Resultado esperado:

```text
active
enabled
```

### 2. ¿Con qué usuario corre?

**Terminal B.**

```bash
ps -o user,pid,comm -C systemd-timesyncd
ps -o user:20,pid,comm -C systemd-timesyncd
systemctl show -p User systemd-timesyncd
```

Ejemplo de salida:

```text
USER         PID COMMAND
systemd+     304 systemd-timesyn

USER                     PID COMMAND
systemd-timesync         304 systemd-timesyn

User=systemd-timesync
```

En la primera salida, `systemd+` es el nombre recortado, porque `ps` deja ocho caracteres para el usuario. Con `user:20` se ve completo. El servicio corre con su propia cuenta, `systemd-timesync`. Si tuviera una falla, el daño quedaría limitado a esa cuenta.

Mirá dónde lo define la unidad:

```bash
systemctl cat systemd-timesyncd | grep -E '^(ExecStart|User)='
```

Resultado esperado:

```text
ExecStart=!!/usr/lib/systemd/systemd-timesyncd
User=systemd-timesync
```

`ExecStart` es el programa que ejecuta el servicio. Los `!!` son un prefijo interno de systemd y no hace falta prestarles atención.

### 3. Detenerlo e iniciarlo

**Terminal B.**

```bash
sudo systemctl stop systemd-timesyncd
systemctl is-active systemd-timesyncd
timedatectl
```

Resultado esperado, en las líneas que importan:

```text
inactive
...
System clock synchronized: yes
              NTP service: inactive
```

`NTP service: inactive` confirma que el servicio de hora está detenido. `System clock synchronized` puede seguir en `yes` un rato, porque muestra cómo quedó el reloj.

Volvé a iniciarlo:

```bash
sudo systemctl start systemd-timesyncd
systemctl is-active systemd-timesyncd
timedatectl | grep 'NTP service'
```

Resultado esperado:

```text
active
              NTP service: active
```

### 4. Deshabilitarlo y habilitarlo

**Terminal B.**

```bash
sudo systemctl disable systemd-timesyncd
```

Resultado esperado:

```text
Removed '/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service'.
Removed '/etc/systemd/system/dbus-org.freedesktop.timesync1.service'.
```

Ahora mirá las dos preguntas:

```bash
systemctl is-enabled systemd-timesyncd
systemctl is-active systemd-timesyncd
```

Resultado esperado:

```text
disabled
active
```

Ya no arrancaría con el sistema, pero **sigue corriendo**. `disable` cambia lo que pasa en el próximo arranque y no toca el proceso que está corriendo ahora.

Habilitalo otra vez:

```bash
sudo systemctl enable systemd-timesyncd
systemctl is-enabled systemd-timesyncd
```

Resultado esperado:

```text
Created symlink '/etc/systemd/system/dbus-org.freedesktop.timesync1.service' → '/usr/lib/systemd/system/systemd-timesyncd.service'.
Created symlink '/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service' → '/usr/lib/systemd/system/systemd-timesyncd.service'.
enabled
```

### 5. Leé su registro

**Terminal B.** Primero sin `sudo`:

```bash
journalctl -u systemd-timesyncd -n 10
```

Resultado esperado:

```text
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal' can see all messages.
      Pass -q to turn off this notice.
-- No entries --
```

Tu usuario no está en esos grupos y por eso no ve el registro del sistema. Con `sudo`:

```bash
sudo journalctl -u systemd-timesyncd -n 10
```

Ejemplo de salida:

```text
sep 27 22:49:49 lab2-vm systemd-timesyncd[1098]: Initial clock synchronization to Sun 2026-09-27 22:49:49.261897 -03.
sep 27 23:56:27 lab2-vm systemd[1]: Stopping systemd-timesyncd.service - Network Time Synchronization...
sep 27 23:56:27 lab2-vm systemd[1]: systemd-timesyncd.service: Deactivated successfully.
sep 27 23:56:27 lab2-vm systemd[1]: Stopped systemd-timesyncd.service - Network Time Synchronization.
sep 27 23:56:32 lab2-vm systemd[1]: Starting systemd-timesyncd.service - Network Time Synchronization...
sep 27 23:56:32 lab2-vm systemd[1]: Started systemd-timesyncd.service - Network Time Synchronization.
sep 27 23:56:32 lab2-vm systemd-timesyncd[1819]: Contacted time server 162.159.200.123:123 (0.debian.pool.ntp.org).
sep 27 23:56:32 lab2-vm systemd-timesyncd[1819]: Initial clock synchronization to Sun 2026-09-27 23:56:32.634280 -03.
```

Buscá tus propias acciones: el `stop` y el `start` del paso 3 quedaron registrados con su hora, y después del `start` el servicio volvió a consultar un servidor de tiempo. El número entre corchetes es el PID de cada proceso; cambió porque el servicio se reinició.

### 6. ¿Y si lo termino con kill?

**Terminal B.**

```bash
systemctl show -p MainPID systemd-timesyncd
```

Ejemplo de salida:

```text
MainPID=1819
```

Terminá ese proceso con `sudo kill` y consultá de nuevo:

```bash
sudo kill 1819
systemctl show -p MainPID systemd-timesyncd
systemctl is-active systemd-timesyncd
```

Ejemplo de salida:

```text
MainPID=1910
active
```

El PID cambió y el servicio sigue activo. systemd lo volvió a iniciar porque su unidad tiene `Restart=always`. Para detener un servicio se usa `systemctl stop`.

## 7. Revisión mínima del servidor

**Terminal B.**

```bash
systemctl list-units --type=service --state=running
systemctl --failed
sudo ss -tlnp
```

Ejemplo de salida (recortada):

```text
  UNIT                      LOAD   ACTIVE SUB     DESCRIPTION
  cron.service              loaded active running Regular background program processing daemon
  ssh.service               loaded active running OpenBSD Secure Shell server
  systemd-timesyncd.service loaded active running Network Time Synchronization
  ...
11 loaded units listed.

  UNIT LOAD ACTIVE SUB DESCRIPTION

0 loaded units listed.

State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=714,fd=6))
LISTEN 0      128             [::]:22           [::]:*    users:(("sshd",pid=714,fd=7))
```

En la VM del curso corren 11 servicios. Es una lista corta y conviene reconocerlos todos; al pie aparece una leyenda que explica las columnas. `--failed` no muestra ninguno, y `ss` indica que el único puerto abierto es el 22, de `sshd`. Lo vamos a ver en detalle en la clase de redes.

## 8. Verificación final

### 1. Comprobá el estado

**Terminal B.**

```bash
systemctl is-active systemd-timesyncd
systemctl is-enabled systemd-timesyncd
pgrep -a yes
pgrep -a sleep
command -v htop pstree killall
```

Resultado esperado:

```text
active
enabled
/usr/bin/htop
/usr/bin/pstree
/usr/bin/killall
```

| Elemento | Estado esperado |
| --- | --- |
| `systemd-timesyncd` | `active` y `enabled` |
| `yes` y `sleep` | Ningún proceso (`pgrep` sin salida) |
| `htop`, `pstree`, `killall` | Instalados |

Si el servicio quedó `inactive`, ejecutá `sudo systemctl start systemd-timesyncd`. Si quedó `disabled`, ejecutá `sudo systemctl enable systemd-timesyncd`.

### 2. Respondé a partir de lo observado

1. ¿Qué diferencia hay entre el número de trabajo `[1]` y el PID?
2. ¿Qué le pasó a `sleep 400` al presionar `Ctrl+Z`? ¿Cómo lo comprobaste?
3. ¿Por qué `jobs` no mostró en B los trabajos de A, y `pgrep` sí?
4. ¿Qué cambió en `jobs -l` y en la columna `STAT` después de `bg %2`?
5. ¿Cómo obtuviste el PID de `yes`? ¿Qué línea de `ps -ef | grep yes` no había que terminar?
6. ¿Por qué no pudiste terminar el `sleep` lanzado con `sudo -b`?
7. Después de `disable`, ¿el servicio seguía corriendo? ¿Qué pasaría al reiniciar?
8. ¿Con qué usuario corre `systemd-timesyncd`? ¿Por qué `ps` mostraba `systemd+`?
9. ¿Qué hizo systemd cuando terminaste su proceso con `kill`?

### 3. Cerrá las sesiones

Cerrá las terminales A y B con `exit`. No hace falta deshacer nada; `htop` y `psmisc` quedan instalados para las próximas clases.

## Resumen del laboratorio

- Un proceso tiene PID, usuario y un proceso padre. `pstree -sp $$` muestra el camino desde PID 1 hasta tu shell.
- `Ctrl+Z` suspende un trabajo, `bg` lo deja seguir en segundo plano, `fg` lo trae al primer plano y `Ctrl+C` lo interrumpe. Cada shell tiene sus propios trabajos.
- Con `top` y `htop` vemos qué consume, con `pgrep -a` o `ps -ef | grep` obtenemos el PID, y con `kill` lo terminamos. `killall` actúa por nombre.
- Cada usuario solo puede terminar sus procesos. Para los de otros hace falta `sudo`.
- `start` y `stop` deciden si el servicio corre ahora, y `enable` y `disable`, si arranca con el sistema.
- `sudo journalctl -u` muestra el registro de un servicio. Para detener un servicio se usa `systemctl stop`.

## Enlaces útiles y referencias

- Ayuda en Debian: `man ps`, `man pstree`, `man top`, `man htop`, `help jobs`, `help kill`, `man killall`, `man systemctl`, `man journalctl`.
- [systemctl(1)](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html) y [journalctl(1)](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html).
- [systemd-timesyncd.service(8)](https://www.freedesktop.org/software/systemd/man/latest/systemd-timesyncd.service.html).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
