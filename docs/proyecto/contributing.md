# Contribuir

Nos emociona que estés interesado en contribuir a nuestro proyecto. Esta guía está diseñada para ayudarte a entender cómo puedes colaborar con  nosotros, ya sea corrigiendo errores, mejorando la documentación,  agregando nuevas características o cualquier otra forma de contribución  que desees realizar.

Para incorporar una función en la rama `main`, simplemente se crea un "PR" (Pull Request), que deberá ser aprobado por algún colaborador. Cualquier colaborador puede hacerlo, o bien, si no requiere revisión, puede ser aceptado por quien esté incluyendo la funcionalidad.

Es crucial que el nombre de las ramas creadas sea lo más descriptivo posible. Por ejemplo, si trabajamos en una nueva funcionalidad relacionada con la API, la rama se debe llamar como referencia a la funcionalidad en cuestión. En el caso de tratarse de la corrección de un error en el código de la API, la llamaremos `fix-api`.

Este proceso asegura un flujo de trabajo ordenado y facilita la colaboración entre los miembros del equipo.

Los pasos para contribuir en este proyecto como individuo son:

1. Forkear el repositorio (`git fork`)
2. Crear una nueva rama para la función (`git checkout -b feature/AmazingFeature`)
3. Publicar la rama en el repositorio remoto(`git push --set-upstream origin <nombre-de-la-nueva-rama>`)
4. Commit los cambios (`git commit -m 'Add some AmazingFeature'`)
5. Push a la rama (`git push origin feature/AmazingFeature`)
6. Abrir un Pull Request dirigido a la rama `develop`