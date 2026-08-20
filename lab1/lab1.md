# Laboratorio 1 - Máquinas virtuales

## Objetivo

  - Instalar VirtualBox (hipervisor tipo 2)
  - Ver conceptos básicos de virtualización
  - Creación de una máquina virtual

## 0. Preparación del Entorno

Primero, vamos a verificar que nuestra computadora soporte y tenga habilidado las instrucciones de virtualización AMD-V o VT-x para procesadores AMD e Intel respectivamente.


#### En Windows

- Vamos al administrador de tareas.
- Rendimiento > CPU.
- Abajo a la derecha, entre las distintas características del procesador deberíamos ver `Virtualización`.
- Debería estar `Habilitado`.

    ![Screenshot](../img/lab1/img1.png)


#### En GNU/Linux

Con el siguiente comando podemos ver si tenemos habilitada la virtualización:

```bash
lscpu | grep -i virtuli
```

##### Deberías ver algo así

```bash

Virtualization:         AMD-V   # Para procesadores AMD
---
Virtualización:         VT-x    # Para procesadores Intel    
```

### Virtualización deshabilitada

Algunos fabricantes deshabilitan por defecto la virtualización del procesador. Para activarlo manualmente, debemos reiniciar la computadora, entrar a la BIOS y buscar la opción para habilitar `VT-x`, `SVM` o `Virtualization` en las opciones avanzadas del CPU. Dichas opciones cambian según fabricante. Actualmente todos los procesadores soportan instrucciones de virtualización en el procesador, por lo que debería ser solo de configuración.




## 1. Descargamos Virtualbox

Vamos a descargar del sitio oficial el instalador de Virtualbox en [este link](https://www.virtualbox.org/wiki/Downloads).


- Seguir los pasos según su sistema operativo: En Windows suele ser descargar el instalador y dar todo siguiente.
- En alguna distro de Linux, ver las instruccioines [acá](https://www.virtualbox.org/wiki/Linux_Downloads). Hay varias opciones; se puede descargar el `.deb` (Debian/Ubuntu), `.rpm` (para distros Oracle/RHEL) o descargarlo agregando los repositorios oficiales.
- Si descargaste el `.deb` lo podés instalar con el siguiente comando:
    ```bash
    sudo apt install ./virtualbox-7.2*.deb
    ```
- Una vez instalado reiniciar la computadora.

### Opcional: Descargar Extension Pack

Opcionalmente podemos descargar las VirtualBox Extension Pack.
El Extension Pack es un paquete binario complementario que añade funciones avanzadas a VirtualBox (como soporte para USB 2.0/3.0, cifrado de imágenes de disco, arranque por NVMe y el servidor RDP integrado llamado VRDP); se distribuye bajo la Licencia de Uso Personal y Evaluación de VirtualBox **(PUEL)**, la cual permite su uso gratuito únicamente para fines estrictamente personales, educativos o de evaluación temporal sin fines comerciales, prohibiendo expresamente su despliegue operativo en empresas o con propósitos comerciales sin haber adquirido antes una licencia comercial de pago con Oracle.

Para nuestro curso, su descarga es opcional.
Una vez descargado debe ejecutarse, aceptar la licencia y se instala automáticamente sobre VirtualBox.

En sistemas Linux, además debe agregarse al usuario como miembro de `vboxusers` para tener compatibilidad.

```bash
sudo usermod -aG vboxusers $USER
```

## 2. Iniciando Virtualbox

Al iniciar VirtualBox, si todo está bien debería abrir la siguiente ventana:

![](../img/lab1/img2.png)


## 3. Creando una VM




Vamos a descargar una `iso` que es para probar la VM. Usaremos la distro [TinyCore](http://www.tinycorelinux.net). Descargaremos desde [acá](http://www.tinycorelinux.net/17.x/x86/release/TinyCore-current.iso).


img3
img4
img41
img42
img43



## 4. Iniciando una VM
img6
img43
img5

## 5. 

## Resumen de Lab

En este laboratorio vimos las diferencias de performance entre bind mounts, named volumes y tmpfs, utilizando la herramienta dd para medir el rendimiento de los volúmenes.

## Links útiles

![](https://download.virtualbox.org/virtualbox/7.2.8/SDKRef.pdf)

-----

<p align="center"\>
<img src="../img/logos.footer.gray.webp"\>
</p\>

-----