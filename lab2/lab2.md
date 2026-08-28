# Laboratorio 2 - Instalación de Debian 13

## Objetivo

  - Crear una máquina virtual con disco propio (a diferencia del Lab 1, acá el sistema queda instalado, no corre solo en RAM)
  - Instalar Debian 13 (*Trixie*) de punta a punta, usando el instalador gráfico
  - Configurar idioma, ubicación, teclado, red, usuarios, particionado de disco, gestor de paquetes y el cargador de arranque GRUB
  - Dejar la cuenta `root` sin contraseña y administrar el sistema a través de `sudo` con el usuario normal


### En este lab usaremos Debian 13 (Trixie)

[**Debian**](https://www.debian.org/) es una de las distribuciones GNU/Linux más estables, y la que vamos a usar como base para el resto del curso. Vamos a instalar desde la imagen `netinst` (instalación por red): es liviana porque trae solo lo mínimo para arrancar el instalador y va descargando el resto de los paquetes desde un repositorio (mirror) durante la instalación.

> Este laboratorio da por sentado que ya tenés VirtualBox instalado (ver [Laboratorio 1](../lab1/lab1.md)).

## 0. Preparación del Entorno

Antes de arrancar, descargamos la imagen ISO `netinst` de Debian 13 (amd64) desde el [sitio oficial](https://www.debian.org/distrib/netinst). En nuestro caso descargamos [`debian-13.6.0-amd64-netinst.iso`](https://saimei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso).

Como en este lab vamos a instalar el sistema operativo de forma persistente, esta vez sí creamos un disco duro virtual (en el Lab 1 no hacía falta porque TinyCore booteaba entero en RAM).

## 1. Creando la VM

1. Abrimos VirtualBox y creamos una nueva máquina virtual. La llamamos `Lab2` y en **ISO Image** apuntamos al instalador de Debian que descargamos. VirtualBox detecta automáticamente el sistema operativo (`Linux` / `Debian` / `Debian 13 Trixie (64-bit)`) a partir del nombre del archivo.

   Dejamos **destildada** la opción **Proceed with Unattended Installation**, porque en este lab queremos recorrer la instalación manualmente, paso a paso.

![](img/lab2_01.png)

2. Le asignamos los recursos de hardware virtual: `1024 MB` de RAM y `1 vCPU`. Y tildamos la opción `Use EFI`.

![](img/lab2_02.png)

3. Creamos un disco duro virtual nuevo, formato `VDI`, de `20 GB` (tamaño dinámico: el archivo va creciendo a medida que lo usamos, hasta ese tope).

![](img/lab2_03.png)

4. Hacemos clic en **Terminar**. VirtualBox nos devuelve a la *Home*, donde ya vamos a ver nuestra VM `Lab2` creada.

## 2. Iniciando la instalación

1. Seleccionamos `Lab2` y le damos **Iniciar**. La VM bootea desde la ISO de Debian y nos muestra el menú del instalador.

2. Elegimos **Graphical install**, la opción con interfaz gráfica (más cómoda que instalar en modo texto).

![](img/lab2_04.png)

## 3. El instalador de Debian

### 3.1 Idioma, ubicación y teclado

1. El instalador arranca en inglés, mostrando la lista completa de idiomas disponibles. Buscamos y seleccionamos `Spanish - Español`. A partir de acá, todo el instalador (y el sistema instalado) va a quedar en español.

![](img/lab2_05.png)

2. Elegimos nuestra ubicación (`Argentina`), que el instalador usa, entre otras cosas, para fijar la zona horaria.

![](img/lab2_06.png)

3. Configuramos la distribución del teclado, en mi caso es `Latinoamericano`.

![](img/lab2_07.png)

### 3.2 Red

1. El instalador pide el **nombre de la máquina** (hostname). En esta instalación usamos `lab2-vm`.

![](img/lab2_08.png)

> Si estuviéramos en una red con dominio, el instalador también preguntaría el nombre de dominio. En una red doméstica o de laboratorio como esta, ese paso no aparece o se puede dejar en blanco.

### 3.3 Usuarios y contraseñas

1. Configuramos la contraseña del superusuario (`root`). Esta vez la **dejamos en blanco a propósito**.

![](img/lab2_09.png)

> El propio instalador nos explica qué implica esto: si dejamos esta contraseña vacía, la cuenta `root` queda **bloqueada** (no se puede iniciar sesión con ella ni loguearse como root directamente), y en su lugar se usa la cuenta del usuario normal que creamos a continuación, agregada automáticamente al grupo `sudo`, para las tareas administrativas. Es el esquema que usan Ubuntu y muchas instalaciones modernas de servidores: **nadie loguea como root**, todos administran vía `sudo` con su propio usuario y su propia contraseña.

2. Creamos un usuario normal del sistema, indicando su nombre completo. En mi caso pondré `cristian`.

![](img/lab2_10.png)

3. Definimos la contraseña para ese usuario (en este caso, `linux410`).

![](img/lab2_11.png)

### 3.4 Particionado de discos

1. Elegimos el método de particionado. Usamos **Guiado - utilizar todo el disco**, la opción más simple para un primer lab.

![](img/lab2_12.png)

2. Seleccionamos el disco a particionar: el disco virtual de `21.5 GB` que le creamos a la VM.

![](img/lab2_13.png)

3. Elegimos el esquema **Todos los ficheros en una partición (recomendado para novatos)**.

![](img/lab2_14.png)

4. El instalador muestra un resumen: va a crear una partición primaria `ESP` de `1.0 GB` (partición EFI), otra partición primaria `ext4` de `19.4 GB` para `/` y una partición lógica de `1.1 GB` de `intercambio` (swap). Seleccionamos **Finalizar el particionado y escribir los cambios en el disco**.

![](img/lab2_15.png)

5. Pide confirmación, detallando exactamente qué particiones va a formatear. Elegimos **Sí**.

![](img/lab2_16.png)

> ⚠️ Este paso borra todo lo que hubiera en el disco seleccionado. Al ser un disco virtual nuevo no hay riesgo acá, pero en un disco real es el momento de prestar mucha atención.

### 3.5 Gestor de paquetes

1. El instalador escanea el medio de instalación y nos pregunta si queremos analizar medios adicionales. Como no tenemos otro disco o ISO, respondemos **No**.

![](img/lab2_17.png)

2. Elegimos el país para buscar una réplica (*mirror*) de Debian cercana: `Argentina`.

![](img/lab2_18.png)

3. Seleccionamos la réplica a usar. `deb.debian.org` es una buena opción por defecto.

![](img/lab2_19.png)

4. Como no usamos proxy para salir a internet, dejamos el campo de proxy HTTP en blanco.

![](img/lab2_20.png)

> Para este paso la VM necesita salida a internet. Por defecto VirtualBox configura el adaptador de red en modo NAT, así que debería funcionar sin configuración adicional.

### 3.6 Selección e instalación de programas

1. Nos pregunta si queremos participar de la encuesta de uso de paquetes (`popularity-contest`). Elegimos **No**.

![](img/lab2_21.png)

2. En la selección de programas **no** tildamos ningún entorno de escritorio: vamos a instalar un servidor sin interfaz gráfica. Dejamos marcadas `SSH server` y `Utilidades estándar del sistema`.

![](img/lab2_22.png)

   Al continuar, el instalador descarga e instala automáticamente los paquetes correspondientes a lo que elegimos. No hace falta ninguna acción más hasta que termine.

> Como este curso es de administración de servidores, vamos a trabajar directo desde la terminal. Si quisiéramos una VM de escritorio, acá elegiríamos GNOME, Xfce, KDE Plasma, u otro entorno.

### 3.7 Cargador de arranque (GRUB)

1. El instalador detecta que esta instalación sería el único sistema operativo del equipo, y pregunta si queremos instalar el cargador de arranque **GRUB** en la unidad principal. Respondemos **Sí**.

![](img/lab2_23.png)

2. Elegimos el dispositivo donde instalar GRUB: `/dev/sda`, el disco virtual de la VM.

![](img/lab2_24.png)

### 3.8 Fin de la instalación

1. El instalador avisa que la instalación se completó. Le damos **Continuar** para reiniciar la VM.

![](img/lab2_25.png)

> El propio instalador recuerda extraer el medio de instalación para que la VM arranque desde el disco y no vuelva a mostrar el instalador. VirtualBox suele encargarse de esto automáticamente.

## 4. Primer arranque

1. Al reiniciar, ya no vemos el instalador sino el cargador de arranque **GRUB**, cargando el kernel de Debian.

![](img/lab2_26.png)

2. El sistema termina de arrancar y llegamos a la pantalla de login en modo texto.

![](img/lab2_27.png)

3. Iniciamos sesión con el usuario que creamos durante la instalación (`cristian` / `linux410`).

  Si el inicio fue exitoso.. ¡Genial! hemos instalado un GNU/Linux desde 0.

4. Apagamos la VM:
   - Escribiendo el siguiente comando:
     ```bash
      sudo shutdown now
      # Nos pedirá la contraseña que le pusimos al usuario.
     ```

   > El comando `sudo` se utiliza para elevar los privilegios de un usuario. Lo veremos con mas detalle la clase que viene.

   - O bien cerrando la ventana de la VM y luego dando clic en `Enviar señal de apagado` como muestra el siguiente screenshot. Este es el apagado "amable" desde la VM.

![](img/lab2_28.png)



## Resumen de Lab

En este laboratorio instalamos Debian 13 (Trixie) de cero dentro de una máquina virtual, esta vez con un disco duro persistente en lugar de bootear en RAM. Recorrimos el instalador gráfico completo: selección de idioma, ubicación y teclado; configuración de red (hostname `lab2-vm`); creación de usuarios; particionado guiado del disco; configuración del gestor de paquetes y su réplica; selección de programas (optamos por un servidor sin entorno de escritorio, con SSH); e instalación del cargador de arranque GRUB. 

## Links útiles

- [Apuntes teóricos](https://linux.idepba.com.ar/)
- [Sitio oficial de Debian](https://www.debian.org/)
- [Descarga de Debian netinst](https://www.debian.org/distrib/netinst)
- [Manual de instalación de Debian](https://www.debian.org/releases/stable/installmanual)
- [sudo - Debian Wiki](https://wiki.debian.org/sudo/)

-----

<p align="center"\>
<img src="../img/logos.footer.gray.webp"\>
</p\>
