---
title: "Переопределяем расположение .env файла для Laravel"
slug: override-laravel-env-file-location
date: 2018-08-23T16:43:45Z
featured_image: /images/posts/laravel-wide.png
tags:
- php
- laravel
- phpunit
---

Столкнулся с ситуацией, когда необходимо переопределить расположение `.env` файла, который используется, к примеру - для запуска `phpunit` тестов. Да, если в корне приложения имеется файл `.env.testing` - то он автоматически будет прочитан фреймворком при `APP_ENV` равным `testing`, но вот что делать, если этот файл необходимо разметить в какой-либо другой директории? Давай расположим его в `./env.d/` дабы, например, не "мусорить" в корне приложения.

<!--more-->

Как оказалось - делается это не совсем очевидно. Давай рассмотрим файл `./tests/CreatesApplication.php`, который ты наверняка юзаешь для создания экземпляра приложения:

```php
<?php

namespace Tests;

use Illuminate\Contracts\Console\Kernel;

trait CreatesApplication
{
    /**
     * Creates the application.
     *
     * @return \Illuminate\Foundation\Application
     */
    public function createApplication()
    {
        $app = require __DIR__.'/../bootstrap/app.php';

        $app->make(Kernel::class)->bootstrap();

        return $app;
    }
}
```

Теперь, чтобы "заставить" приложение читать все переменные окружения из того файла который мы укажем далее, необходимо его изменить до примерно следующего вида:

```php
<?php

namespace Tests;

use Illuminate\Foundation\Application;
use Illuminate\Contracts\Console\Kernel;

trait CreatesApplication
{
    /**
     * Creates the application.
     *
     * @return Application
     */
    public function createApplication()
    {
        /** @var Application $app */
        $app = require __DIR__.'/../bootstrap/app.php';

        $this->beforeApplicationBootstrapped($app);

        $app->make(Kernel::class)->bootstrap();

        return $app;
    }

    /**
     * Make some before application bootstrapped (call "$app->useStoragePath(...)",
     * "$app->loadEnvironmentFrom(...)", etc).
     *
     * @return void
     */
    protected function beforeApplicationBootstrapped(Application $app)
    {
        $app
            ->useEnvironmentPath($path = realpath(__DIR__ . '/../env.d'))
            ->loadEnvironmentFrom($file = '.env.testing');

        // Make overriding (see "env()" usage)
        (new \Dotenv\Dotenv($path, $file))->load();
    }
}
```

Вот теперь он будет корректно прочитан из `./env.d/.env.testing`, и более того - в любом тесте мы можем спокойно переопределить метод `beforeApplicationBootstrapped()` наделив его тем функционалом, который нам необходим.
