<a name="readme-top"></a>

## Actualización Homeharbor — 11 de noviembre de 2026

La interfaz se migró a **React 19.3.1**, **Vite 8.3.8**, **Tailwind 4.3.5**, **React Router 7.18.5** y **Node 26.13.1 LTS**. Usar la versión indicada en `.node-version`/`.nvmrc` y el lockfile versionado:

```sh
npm ci
npm run dev
npm run lint
npm test
npm run build
```

Desarrollo: `http://127.0.0.1:5173`. Build: `dist/`. `npm run preview` permite inspeccionar el build estático; no incluye el proxy de desarrollo.

Copiar `.env.example` a `.env` si se necesita cambiar `API_PROXY_TARGET`, cuyo valor por defecto es `http://127.0.0.1:3001`. Las llamadas pasan por `/api`; las llamadas antiguas de autenticación usan `/legacy-auth`, que Vite reescribe a las rutas del backend académico. Así `/login` y `/signup` siguen siendo pantallas React. En producción se debe configurar el mismo enrutamiento y el fallback de la SPA.

**Estado funcional:** esta actualización conserva las pantallas del proyecto académico. Su login por nombre y API de reservas aún no se han reemplazado por el contrato de Homeharbor; no constituye una plataforma lista para producción. La integración segura se realizará en los siguientes entregables.

ESLint 10 usa una corrección explícita de `minimatch` en `overrides` para evitar GHSA-g3hv-75wg-m249. Revisarla al actualizar ESLint; no eliminarla sin ejecutar lint y auditoría. CI usa `npm ci`, lint, Vitest, build y auditoría.

El resto del README conserva la descripción y atribuciones del proyecto original.
<div align="center">

  <h1><b>Reserve Boats</b></h1>

</div>

<!-- TABLE OF CONTENTS -->

# 📗 Table of Contents

- [📗 Table of Contents](#-table-of-contents)
- [📖 Final Capstone Project Frontend ](#-final-capstone-project-frontend-)
  - [🛠 Built With ](#-built-with-)
    - [Tech Stack ](#tech-stack-)
    - [Key Features ](#key-features-)
  - [🚀 Back End Part ](#-back-end-part-)
  - [💻 Getting Started ](#-getting-started-)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Install](#install)
    - [Usage](#usage)
  - [👥 Authors ](#-authors-)
  - [🔭 Future Features ](#-future-features-)
  - [🤝 Contributing ](#-contributing-)
  - [⭐️ Show your support ](#️-show-your-support-)
  - [🙏 Acknowledgments ](#-acknowledgments-)
  - [📝 License ](#-license-)

<!-- PROJECT DESCRIPTION -->

# 📖 Final Capstone Project Frontend <a name="about-project"></a>

**Reserve Boats** is an innovative web platform crafted using a dynamic tech stack that includes Ruby on Rails with Postgresql, coupled with React, React Router, and Redux. Upon seamless registration and login, users gain access to a plethora of features, such as booking boat rides, adding new boats to the inventory, and effortlessly removing them when needed.

This user-friendly site boasts a responsive design, ensuring a seamless experience across various devices. The aesthetic appeal is enhanced through the implementation of Tailwind CSS, delivering a visually pleasing and intuitive interface. Dive into the world of maritime adventures with Reserve Boats, where simplicity meets functionality."

## 🛠 Built With <a name="built-with"></a>

### Tech Stack <a name="tech-stack"></a>

<details>
  <summary>Client</summary>
  <ul>
    <li><a href="https://es.react.dev/">React</a></li>
  </ul>
</details>


<details>
  <summary>Server</summary>
  <ul>
    <li><a href="https://rubyonrails.org/">Ruby on Rails</a></li>
  </ul>
</details>

<details>
<summary>Database</summary>
  <ul>
    <li><a href="https://www.postgresql.org/">PostgreSQL</a></li>
  </ul>
</details>

<!-- Features -->

### Key Features <a name="key-features"></a>

- **User Sign up and Login/Logout**
- **Load Boat List from the Database**
- **Add and Delete Boats**
- **Create and view Reservations**
- **Sweetalert2 alert messages**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- BACK END PART -->

## 🚀 Back End Part <a name="back-end-part"></a>

The site has 2 separate repositories, this is the Frontend repository.

Link to the [Back End Repository](https://github.com/Felipe-Perez-Ferraro/final_capstone_back)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## 💻 Getting Started <a name="getting-started"></a>

To get a local copy up and running, follow these steps.

### Prerequisites

In order to run this project you need:

- Node.js 26.13.1 LTS and npm (see `.node-version`).

### Setup

Clone this repository to your desired folder:

```sh
  cd my-folder
  git clone https://github.com/Felipe-Perez-Ferraro/final_capstone_front.git
```

### Install

Install this project with:

```sh
  cd my-project
  npm ci
```

### Usage

To run the project, execute the following command:

```sh
  npm start
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- AUTHORS -->

## 👥 Authors <a name="authors"></a>

👤 **Felipe Perez Ferraro**

- GitHub: [@githubhandle](https://github.com/Felipe-Perez-Ferraro)
- LinkedIn: [LinkedIn](https://www.linkedin.com/in/felipe-perez-ferraro-6b9358218/)

👤 **Ulises Cappa**

- GitHub: [@ulises2607](https://github.com/ulises2607)
- LinkedIn: [Cesar Ulises Cappa Subelza](https://www.linkedin.com/in/cesar-ulises-cappa-subelza/)

👤 **Hajnalka Oltyan**

- GitHub: [@hajnaloltyan](https://github.com/hajnaloltyan)
- LinkedIn: [Hajnal Oltyan](https://www.linkedin.com/in/hajnaloltyan)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FUTURE FEATURES -->

## 🔭 Future Features <a name="future-features"></a>

- [ ] **Implementing proper Authentication**
- [ ] **Assigning user roles, like normal user and admin**
- [ ] **Add payment methods**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## 🤝 Contributing <a name="contributing"></a>

Contributions, issues, and feature requests are welcome!

Feel free to check the [issues page](https://github.com/Felipe-Perez-Ferraro/final_capstone_front/issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- SUPPORT -->

## ⭐️ Show your support <a name="support"></a>

If you like this project please share with your friends and family!

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGEMENTS -->

## 🙏 Acknowledgments <a name="acknowledgements"></a>

The design idea is provided by [Murat Korkmaz on Behance](https://www.behance.net/gallery/26425031/Vespa-Responsive-Redesign)

I would like to thank Microverse for teach me and support me to do this.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

## 📝 License <a name="license"></a>

This project is [MIT](./LICENSE) licensed.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
