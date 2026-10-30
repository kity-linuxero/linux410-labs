# Laboratorio 15.1 - Tareas programadas

## Objetivo

- Programar un script con cron y comprobar que corre solo.
- Ver qué pasa con lo que muestra una tarea cuando nadie la mira.
- Mandar los mensajes de la tarea al journal con `logger` y encontrar un error.
- Leer `/etc/anacrontab` y agregar una tarea propia a anacron.

### Punto de partida

Usamos la VM Debian 13 del curso con la cuenta administradora, por ejemplo `cristian`, y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md). No hace falta haber hecho otros laboratorios: el script se crea acá y todo se deshace al final.

> [!NOTE]
> Reemplazá `cristian` por tu usuario. Las fechas, las horas y los números de proceso de las salidas van a ser otros en tu VM.

> [!IMPORTANT]
> Si usás una notebook, dejala enchufada. VirtualBox le pasa a la VM el estado de la batería y, con la notebook desenchufada, anacron no se ejecuta solo.

## 0. Preparación

Desde la máquina anfitriona:

```bash
ssh -p 2222 cristian@localhost
```

Comprobá que cron está en marcha y que la hora de la VM es la correcta. cron ejecuta las tareas según esa hora:

```bash
systemctl is-active cron
timedatectl
```

```text
active
               Local time: jue 2026-10-29 23:33:12 -03
           Universal time: vie 2026-10-30 02:33:12 UTC
                 RTC time: vie 2026-10-30 02:33:12
                Time zone: America/Argentina/Buenos_Aires (-03, -0300)
System clock synchronized: no
              NTP service: active
          RTC in local TZ: no
```

Si la zona horaria no es la tuya, corregila con `timedatectl set-timezone`, como en el [Laboratorio 3](../lab3/lab3.md). `System clock synchronized: no` es normal al rato de prender la VM: en un par de minutos se sincroniza sola.

## 1. El script

Vamos a programar un script que copia los registros de apt en un directorio. Es el de la [clase 15](https://linux.idepba.com.ar/clase15.html), con un cambio: el nombre de la copia lleva también la hora y los minutos (`%H%M`). Así cada ejecución deja su propia copia aunque corra varias veces en el día.

Si ya tenés `/usr/local/sbin/archivar.sh` del Laboratorio 14, reemplazalo por esta versión. Abrí el archivo con `sudo`, porque `/usr/local/sbin` es de `root`:

```bash
sudo nano /usr/local/sbin/archivar.sh
```

Borrá lo que hubiera y escribí:

```bash
#!/bin/bash
# Copia los registros de apt en el directorio que se indica

DESTINO=$1
FECHA=$(date +%F-%H%M)

if [ -z "$DESTINO" ]; then
    echo "Uso: $0 directorio" >&2
    exit 1
fi

if [ ! -d "$DESTINO" ]; then
    echo "No existe el directorio $DESTINO" >&2
    exit 1
fi

cp -r /var/log/apt "$DESTINO/apt-$FECHA"

if [ $? -ne 0 ]; then
    echo "No se pudo copiar" >&2
    logger -t archivar -p user.err "Falló la copia en $DESTINO"
    exit 1
fi

echo "Listo: $DESTINO/apt-$FECHA"
logger -t archivar "Copia en $DESTINO"
```

Guardá con `Ctrl+O` y `Enter`, y salí con `Ctrl+X`. Dejalo con dueño `root` y modo 755, creá el directorio de las copias y probalo a mano:

```bash
sudo chown root:root /usr/local/sbin/archivar.sh
sudo chmod 755 /usr/local/sbin/archivar.sh
sudo mkdir -p /srv/respaldos
sudo /usr/local/sbin/archivar.sh /srv/respaldos
```

```text
Listo: /srv/respaldos/apt-2026-10-29-2333
```

Una tarea que no funciona a mano tampoco va a funcionar en cron. Siempre conviene probarla antes.

## 2. La primera tarea con cron

### 1. Abrir el crontab de root

La copia necesita leer `/var/log/apt`, que solo `root` puede leer completo. Por eso la tarea va en el crontab de `root`:

```bash
sudo crontab -l
```

```text
no crontab for root
```

Todavía no tiene ninguna tarea. Abrilo para editar:

```bash
sudo crontab -e
```

La primera vez pregunta qué editor usar:

```text
Select an editor.  To change later, run select-editor again.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.tiny

Choose 1-2 [1]:
```

Escribí `1` y `Enter` para elegir `nano`. No lo vuelve a preguntar.

### 2. Una tarea cada dos minutos

Al final del archivo, debajo de los comentarios, agregá esta línea:

```
*/2 * * * * /usr/local/sbin/archivar.sh /srv/respaldos
```

- Los cinco campos son minuto, hora, día del mes, mes y día de la semana.
- `*/2` en el minuto quiere decir «cada dos minutos». Los `*` quieren decir «cualquiera».
- El script va con la ruta completa: cron no tiene `/usr/local/sbin` en su `PATH`.

Guardá y salí. Al guardar, `crontab` revisa la línea y avisa:

```text
crontab: installing new crontab
```

Si te equivocás en un campo, no la instala. Por ejemplo, con `99` en el minuto:

```text
"/tmp/crontab.PFhgtV/crontab":3: bad minute
errors in crontab file, can't install.
Do you want to retry the same edit? (y/n)
```

Con `y` vuelve a abrir el editor para corregir.

### 3. ¿Corrió?

Esperá unos minutos y mirá el directorio:

```bash
ls /srv/respaldos
```

```text
apt-2026-10-29-2333  apt-2026-10-29-2334  apt-2026-10-29-2336
```

La primera copia es la que hiciste a mano. Las otras las hizo cron, una cada dos minutos.

Cada ejecución también queda en el journal del servicio `cron`. Hace falta `sudo` porque tu cuenta no está en el grupo `adm`:

```bash
sudo journalctl -u cron --since "10 min ago"
```

```text
oct 29 23:34:04 lab2-vm CRON[913]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
oct 29 23:34:04 lab2-vm CRON[915]: (root) CMD (/usr/local/sbin/archivar.sh /srv/respaldos)
oct 29 23:34:04 lab2-vm archivar[919]: Copia en /srv/respaldos
oct 29 23:34:04 lab2-vm CRON[913]: (CRON) info (No MTA installed, discarding output)
oct 29 23:34:04 lab2-vm CRON[913]: pam_unix(cron:session): session closed for user root
oct 29 23:36:03 lab2-vm CRON[928]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
oct 29 23:36:03 lab2-vm CRON[930]: (root) CMD (/usr/local/sbin/archivar.sh /srv/respaldos)
oct 29 23:36:03 lab2-vm archivar[934]: Copia en /srv/respaldos
oct 29 23:36:03 lab2-vm CRON[928]: (CRON) info (No MTA installed, discarding output)
oct 29 23:36:03 lab2-vm CRON[928]: pam_unix(cron:session): session closed for user root
```

- `session opened` y `session closed` marcan el principio y el fin de cada ejecución, como cuando alguien entra y sale.
- `CMD` dice qué cuenta ejecutó qué comando.
- `No MTA installed, discarding output`: el script mostró `Listo: ...` y nadie lo vio. cron intenta mandar por correo lo que muestra una tarea. La VM no tiene servidor de correo (MTA), así que lo descarta.

El script además llama a `logger` cuando la copia sale bien. Eso sí quedó:

```bash
sudo journalctl -t archivar --since "10 min ago"
```

```text
oct 29 23:33:18 lab2-vm archivar[885]: Copia en /srv/respaldos
oct 29 23:34:04 lab2-vm archivar[919]: Copia en /srv/respaldos
oct 29 23:36:03 lab2-vm archivar[934]: Copia en /srv/respaldos
```

## 3. Cuando la tarea falla

### 1. Provocar un error

Cambiá el destino por un directorio que no existe:

```bash
sudo crontab -e
```

```
*/2 * * * * /usr/local/sbin/archivar.sh /srv/noexiste
```

Esperá dos minutos y mirá los dos registros:

```bash
sudo journalctl -u cron --since "3 min ago"
sudo journalctl -t archivar --since "3 min ago"
```

```text
oct 29 23:38:03 lab2-vm cron[613]: (root) RELOAD (crontabs/root)
oct 29 23:38:03 lab2-vm CRON[966]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)
oct 29 23:38:03 lab2-vm CRON[968]: (root) CMD (/usr/local/sbin/archivar.sh /srv/noexiste)
oct 29 23:38:03 lab2-vm CRON[966]: (CRON) info (No MTA installed, discarding output)
oct 29 23:38:03 lab2-vm CRON[966]: pam_unix(cron:session): session closed for user root
-- No entries --
```

`RELOAD` dice que cron leyó la tabla nueva.

El script falló y no hay rastro del motivo. Escribió `No existe el directorio /srv/noexiste` por la salida de error y cron lo descartó junto con lo demás. Como sale antes del `cp`, tampoco llegó a llamar a `logger`.

### 2. Mandar todo al journal

Cambiá la línea para que todo lo que muestre el script vaya a `logger`:

```bash
sudo crontab -e
```

```
*/2 * * * * /usr/local/sbin/archivar.sh /srv/noexiste 2>&1 | logger -t archivar
```

- `| logger -t archivar` toma lo que entra por la tubería y lo escribe en el journal con la etiqueta `archivar`.
- La tubería solo lleva la salida normal. `2>&1` manda la salida de error al mismo lugar, así los errores también llegan a `logger`.

Esperá dos minutos:

```bash
sudo journalctl -t archivar --since "3 min ago"
```

```text
oct 29 23:40:02 lab2-vm archivar[1021]: No existe el directorio /srv/noexiste
```

Ahora el error queda guardado. Si quitás el `2>&1` y esperás otra vez, vas a ver que no aparece nada: el mensaje sale por la salida de error y no pasa por la tubería.

### 3. Corregir el destino

Volvé a `/srv/respaldos`, manteniendo el `2>&1 | logger`:

```
*/2 * * * * /usr/local/sbin/archivar.sh /srv/respaldos 2>&1 | logger -t archivar
```

A los dos minutos:

```bash
sudo journalctl -t archivar --since "3 min ago"
```

```text
oct 29 23:44:02 lab2-vm archivar[1103]: Copia en /srv/respaldos
oct 29 23:44:02 lab2-vm archivar[1101]: Listo: /srv/respaldos/apt-2026-10-29-2344
```

`Copia en ...` la escribe el `logger` que está adentro del script. `Listo: ...` es el `echo` del script, que llegó por la tubería al `logger` de la línea de cron. Por eso tienen distinto número de proceso.

## 4. Una vez por día

Cada dos minutos sirve para probar. Para un respaldo real, una vez por día alcanza. Dejala a las 2:30:

```
30 2 * * * /usr/local/sbin/archivar.sh /srv/respaldos 2>&1 | logger -t archivar
```

```bash
sudo crontab -l | grep -v '^#'
```

```text
30 2 * * * /usr/local/sbin/archivar.sh /srv/respaldos 2>&1 | logger -t archivar
```

El `grep -v '^#'` oculta los comentarios. Si la VM está apagada a las 2:30, ese día la tarea no corre: cron no recupera lo que se perdió. Para eso está anacron.

> [!TIP]
> [crontab.guru](https://crontab.guru/) traduce una línea de cron a palabras. Sirve para comprobar los campos antes de guardar.

## 5. anacron

### 1. Leer /etc/anacrontab

anacron viene instalado en la VM. Su tabla es una sola, `/etc/anacrontab`, y solo la usa `root`:

```bash
grep -v '^#' /etc/anacrontab | grep -v '^$'
```

```text
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
HOME=/root
LOGNAME=root
1	5	cron.daily	run-parts --report /etc/cron.daily
7	10	cron.weekly	run-parts --report /etc/cron.weekly
@monthly	15	cron.monthly	run-parts --report /etc/cron.monthly
@yearly	20	cron.yearly	run-parts --report /etc/cron.yearly
```

Las primeras líneas son el entorno de las tareas. Después, una tarea por línea, con cuatro campos:

| Campo | En la primera tarea | Qué quiere decir |
| --- | --- | --- |
| Período | `1` | cada cuántos días corre |
| Espera | `5` | minutos que espera desde que arranca anacron |
| Nombre | `cron.daily` | identifica la tarea |
| Comando | `run-parts --report /etc/cron.daily` | lo que ejecuta, como `root` |

La primera línea se lee así: si pasó un día desde la última vez que corrió `cron.daily`, esperar 5 minutos y ejecutar los scripts de `/etc/cron.daily`.

### 2. Dónde anota cuándo corrió

Por cada tarea, anacron guarda la fecha de la última vez en un archivo con el nombre de la tarea:

```bash
sudo ls /var/spool/anacron
sudo cat /var/spool/anacron/cron.daily
```

```text
cron.daily  cron.monthly  cron.weekly  cron.yearly
20261025
```

Con esa fecha decide si una tarea está atrasada. Si la VM estuvo apagada varios días, la primera vez que corre anacron se pone al día.

En este ejemplo la fecha es de cuatro días antes, aunque la VM estuvo prendida: la notebook estaba desenchufada. El journal lo dice:

```bash
sudo journalctl -u anacron --since today
```

```text
oct 29 23:34:31 lab2-vm systemd[1]: anacron.service - Run anacron jobs skipped, unmet condition check ConditionACPower=true
```

`ConditionACPower=true` es una condición del servicio: corre solo con el equipo enchufado. Ejecutado a mano, como en el paso siguiente, anacron corre igual.

### 3. Una tarea propia

Agregá al final de `/etc/anacrontab` una tarea diaria que haga la copia:

```bash
sudo nano /etc/anacrontab
```

```
1	10	archivar	/usr/local/sbin/archivar.sh /srv/respaldos 2>&1 | logger -t archivar
```

Una vez por día, 10 minutos después de que arranque anacron. Revisá que el archivo esté bien escrito:

```bash
sudo anacron -T
```

Si no muestra nada, está bien. Si hay un error, dice en qué línea.

### 4. Ejecutarla a mano

anacron no queda corriendo: en Debian lo llama un temporizador una vez por hora, entre las 7 y las 23. Para no esperar, ejecutá solo tu tarea:

```bash
sudo anacron -n archivar
```

- `archivar` es el nombre de la tarea: ejecuta solo esa.
- `-n` es «ahora»: no espera los 10 minutos.

No muestra nada. anacron deja su propio registro en el journal, con la etiqueta `anacron`:

```bash
sudo journalctl -t anacron --since "2 min ago"
sudo journalctl -t archivar --since "2 min ago"
sudo cat /var/spool/anacron/archivar
```

```text
oct 29 23:45:59 lab2-vm anacron[1280]: Anacron 2.3 started on 2026-10-29
oct 29 23:45:59 lab2-vm anacron[1280]: Will run job `archivar'
oct 29 23:45:59 lab2-vm anacron[1280]: Jobs will be executed sequentially
oct 29 23:45:59 lab2-vm anacron[1280]: Job `archivar' started
oct 29 23:45:59 lab2-vm anacron[1280]: Job `archivar' terminated
oct 29 23:45:59 lab2-vm anacron[1280]: Normal exit (1 job run)
oct 29 23:45:59 lab2-vm archivar[1287]: Copia en /srv/respaldos
oct 29 23:45:59 lab2-vm archivar[1285]: Listo: /srv/respaldos/apt-2026-10-29-2345
20261029
```

La tarea corrió y anacron guardó la fecha de hoy. Ejecutala otra vez:

```bash
sudo anacron -n archivar
sudo journalctl -t anacron --since "1 min ago"
```

```text
oct 29 23:46:02 lab2-vm anacron[1297]: Anacron 2.3 started on 2026-10-29
oct 29 23:46:02 lab2-vm anacron[1297]: Normal exit (0 jobs run)
```

`0 jobs run`: no ejecutó nada. La fecha guardada es la de hoy, y para anacron la tarea ya está hecha. Esa es la diferencia con cron, que ejecuta cada vez que coincide la hora.

## 6. Los temporizadores

Las distribuciones nuevas programan muchas tareas con temporizadores de systemd. Mirá los de la VM:

```bash
systemctl list-timers
```

```text
NEXT                            LEFT LAST                           PASSED UNIT                         ACTIVATES
Fri 2026-10-30 00:39:37 -03    53min Thu 2026-10-29 00:27:43 -03         - logrotate.timer              logrotate.service
Fri 2026-10-30 02:58:25 -03 3h 12min Wed 2026-10-28 20:51:08 -03         - apt-daily.timer              apt-daily.service
Fri 2026-10-30 07:33:35 -03       7h Thu 2026-10-29 23:34:31 -03 11min ago anacron.timer                anacron.service
...
9 timers listed.
```

Buscá `anacron.timer` en la columna `UNIT`: es el que llama a anacron. `NEXT` dice cuándo le toca y `LAST`, cuándo se disparó la última vez. Se disparó a las 23:34, pero anacron no corrió por la batería: `LAST` no dice si el servicio funcionó. También vas a ver `logrotate.timer`, que rota los logs, y `apt-daily.timer`, que baja la lista de paquetes.

## 7. Opcional: lo mismo en Rocky

En Rocky Linux cron se comporta distinto cuando no hay servidor de correo: en lugar de descartar lo que muestra la tarea, lo guarda.

> **¿No tenés la VM de Rocky?** Descargá `Lab_Rocky.ova` y `Lab_Rocky.ova.sha256` de [linux-files.idep.atepba.org.ar](https://linux-files.idep.atepba.org.ar/) y seguí los pasos 2 a 4 del [Laboratorio 10.2](../lab10/lab10.2.md). La cuenta es `usuario`, con contraseña `linux410`, y el SSH está en el puerto 2223.

```bash
ssh -p 2223 usuario@localhost
```

Programá un error en el crontab de `root`, sin `logger`:

```bash
sudo crontab -e
```

```
*/2 * * * * ls /noexiste
```

A los dos minutos:

```bash
sudo tail -n 3 /var/log/cron
```

```text
Oct 29 23:32:01 localhost CROND[2368]: (root) CMD (ls /noexiste)
Oct 29 23:32:01 localhost CROND[2354]: (root) CMDOUT (ls: no se puede acceder a '/noexiste': No existe el fichero o el directorio)
Oct 29 23:32:01 localhost CROND[2354]: (root) CMDEND (ls /noexiste)
```

`CMD` es la ejecución, `CMDOUT` lo que mostró la tarea y `CMDEND` el final. Rocky lo guarda en `/var/log/cron` y en el journal. Borrá la tarea al terminar:

```bash
sudo crontab -r
```

## 8. Limpieza

En la Debian, borrá el crontab de root. `crontab -r` borra la tabla entera, sin preguntar. Si tenías otras tareas de antes, sacá solo la línea con `sudo crontab -e`:

```bash
sudo crontab -r
sudo crontab -l
```

```text
no crontab for root
```

Sacá la línea `archivar` del final de `/etc/anacrontab`, borrá la fecha que guardó y revisá que el archivo quedó bien:

```bash
sudo nano /etc/anacrontab
sudo rm /var/spool/anacron/archivar
sudo anacron -T
```

Borrá las copias:

```bash
sudo rm -r /srv/respaldos
```

Podés dejar `/usr/local/sbin/archivar.sh`. Para borrarlo:

```bash
sudo rm /usr/local/sbin/archivar.sh
```

## Preguntas

1. En el paso 2, el script mostró `Listo: ...` cada dos minutos. ¿Dónde fue a parar ese mensaje? ¿Por qué el `Copia en /srv/respaldos` sí quedó en el journal?
2. ¿Qué pasa con el mensaje de error si en la línea de cron dejás `| logger -t archivar` pero sacás el `2>&1`?
3. ¿Por qué en la línea de cron el script va con la ruta completa?
4. La VM estuvo apagada a las 2:30. ¿Corre ese día la tarea de cron? ¿Y la de anacron?
5. ¿Por qué la segunda vez `sudo anacron -n archivar` no hizo una copia?
6. Si una cuenta común pudiera modificar `/usr/local/sbin/archivar.sh`, ¿qué podría hacer con la tarea programada?

## Resumen del laboratorio

- `sudo crontab -e` edita las tareas de `root`. Cada línea tiene cinco campos de tiempo y el comando, con ruta completa.
- `journalctl -u cron` muestra cada ejecución (`CMD`).
- Sin servidor de correo, Debian descarta lo que muestra la tarea. Con `2>&1 | logger -t etiqueta` queda en el journal y se lee con `journalctl -t`.
- anacron ejecuta una vez por período lo que está en `/etc/anacrontab` y anota la fecha en `/var/spool/anacron`. Si el equipo estuvo apagado, se pone al día.
- `anacron -T` revisa el archivo, `anacron -n tarea` ejecuta una tarea sin esperar y `journalctl -t anacron` muestra qué hizo.

## Enlaces útiles y referencias

- Ayuda en Debian: `man 5 crontab`, `man anacron`, `man 5 anacrontab`, `man logger`.
- [crontab.guru](https://crontab.guru/).
- Clase 16: [presentación](https://linux.idepba.com.ar/clase16.html).
- Anterior: [Laboratorio 14 - Scripts de administración](../lab14/lab14.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
