# A repo for the Grand Finale of Tour de App 2025

# About the team

We are a passionate team **Kapibary** consisting of 3 students from [High School of Technology and Business](https://www.sstebrno.cz), Brno, Czech Republic.
Our team members are:

- [Vitalii Myronov](https://github.com/kekugesso) (team lead) - back-end developer
- [Vojtěch Sládek](https://github.com/VSladek) - front-end developer
- [Karolína Navrátilová](https://github.com/Graysi5371) - designer and tester

We love coding and we are always looking for new challenges. We are excited to participate in the Tour de App 2025 Contest and we hope to win!

# About the app

## Technologies

The app is built using the following technologies:

### Front-end

- [Next.js](https://nextjs.org/)
- [TypeScript](https://www.typescriptlang.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [TenStack Query](https://react-query.tanstack.com/)
- [TenStack Table](https://react-table.tanstack.com/)
- [Shadcn](https://ui.shadcn.com/)

for more info look at the [package.json](./frontend/package.json) file.

### Back-end

- [Django](https://www.djangoproject.com/)
- [Django REST framework](https://www.django-rest-framework.org/)

### Full-stack

- [Docker](https://www.docker.com/)

## Running

To run the app, simply build the docker image, which one takes 10 minutes to build, and run it. The app will be available at `http://localhost:8080`.

```bash
docker build -t app .
docker run -p 8080:80 app
```

### Development

To run the app in development mode, you first need to setup the environment so run the following commands:

```bash
sh start.sh setup-dev
```

or if you are using Windows run the batch file:

```bash
start.bat setup-dev
```

Then you can start the development server:

```bash
sh start.sh dev
```

or if you are using Windows run the batch file:

```bash
start.bat dev
```
