---
title: Сниппеты для WordPress (ч. 1)
date: 2016-01-23T05:35:18+00:00
aliases:
  - /wp/wp-snippets-part-1.html
featured_image: /images/posts/wp-snippets-wide.jpg
tags:
  - code
  - php
  - snippets
  - wordpress
---

> Кэп, "по умолчанию" все сниппеты добавляются в `./wp-content/%theme%/functions.php` твоей темы

### Изменяем путь к статике темы

В ряде случаев полезно вынести всю статику на отдельный субдомен или директорию в корне сайта. Так мы и путь к теме скрываем, и располагаем статический контент "поближе" да поудобнее:

<!--more-->

```php
if( !defined('THEME_ASSETS_URL')) {
  $home_url = esc_url(home_url('/'));
  define('THEME_ASSETS_URL', $home_url.'assets', true);
} else {
  define('THEME_ASSETS_URL', get_template_directory_uri(), true);
}
```

В корне сайта создаем директорию `/assets`, и после в теме используем, например, таким образом:

```php
wp_enqueue_style('responsive', THEME_ASSETS_URL.'/css/responsive.css');
// или
echo '<img src="'.THEME_ASSETS_URL.'/images/user.png" alt="" />';
```

### Заменяем путь к файлу style.css темы

В дополнение к описанному выше сниппету - заменяем `%site_url%/wp-content/themes/%theme_name%/style.css` на `%site_url%/assets/style.css`:

```php
add_filter('stylesheet_uri', 'wpi_stylesheet_uri', 10, 2);

function wpi_stylesheet_uri($stylesheet_uri, $stylesheet_dir_uri){
  return THEME_ASSETS_URL.'/style.css';
}
```

### Заменяем стандартный jQuery на jQuery из CDN

Почти все темы используют эту js-либу. Но вот несколько "но" - "в стоке" её использование раскрывает сам факт использования WP (_так как она загружается из `/wp-includes/`_), да и загружать её лучше будет CDN с точки зрения скорости загрузки сайта. Так же если использовать `jquery-ui` - легко заметить херову кучу различных "модулей" для этой надстройки. Их правда очень много, и каждая тянет за собой массу зависимостей из других "модулей". Не лучше ли будет вместо их вороха использовать один-единственный минифицированный `jquery-ui-core` из CDN? На скорости загрузки это лишь положительно сказывается:

```php
// Заменяем стандартный jQuery тем, что хостится на CDN
function modify_jquery() {
  if(!is_admin()) {
    // Замещаем 'jquery-core'
    wp_deregister_script('jquery-core');
    wp_register_script('jquery-core', '//cdnjs.cloudflare.com/ajax/libs/jquery/1.11.3/jquery.min.js', false, '1.11.3');
    // Замещаем 'jquery-migrate'
    wp_deregister_script('jquery-migrate');
    wp_register_script('jquery-migrate', '//cdnjs.cloudflare.com/ajax/libs/jquery-migrate/1.2.1/jquery-migrate.min.js', array('jquery-core'), '1.2.1');
    // Вместо целой кучи UI jQuery плагинов мы замещаем 'jquery-ui-core'
    // с CDN, который их все содержит
    foreach(array('jquery-ui-core', 'jquery-effects-core', 'jquery-effects-blind', 'jquery-effects-bounce', 'jquery-effects-clip', 'jquery-effects-drop', 'jquery-effects-explode', 'jquery-effects-fade', 'jquery-effects-fold', 'jquery-effects-highlight', 'jquery-effects-pulsate', 'jquery-effects-scale', 'jquery-effects-shake', 'jquery-effects-slide', 'jquery-effects-transfer', 'jquery-ui-accordion', 'jquery-ui-autocomplete', 'jquery-ui-button', 'jquery-ui-datepicker', 'jquery-ui-dialog', 'jquery-ui-draggable', 'jquery-ui-droppable', 'jquery-ui-menu', 'jquery-ui-mouse', 'jquery-ui-position', 'jquery-ui-progressbar', 'jquery-ui-resizable', 'jquery-ui-selectable', 'jquery-ui-slider', 'jquery-ui-sortable', 'jquery-ui-spinner', 'jquery-ui-tabs', 'jquery-ui-tooltip', 'jquery-ui-widget') as $handle) {
      wp_deregister_script($handle);
    }
    wp_register_script('jquery-ui-core', '//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js', array('jquery'), '1.11.4', true);
  }
}

add_action('init', 'modify_jquery');
```

> Сходи на сайт [cdnjs.com](https://cdnjs.com/) - наверняка там же найдешь ресурсы, которые используются у тебя на сайте и которые можно было бы загружать из CDN

### Отключаем wp-embed.min.js

Если его функционал вам не нужен, то отключаем его с потрохами:

```php
// Отключаем wp-embed.min.js
function disable_embeds_init() {
  remove_action('rest_api_init', 'wp_oembed_register_route');
  remove_filter('oembed_dataparse', 'wp_filter_oembed_result', 10);
  remove_action('wp_head', 'wp_oembed_add_discovery_links');
  remove_action('wp_head', 'wp_oembed_add_host_js');
}

add_action('init', 'disable_embeds_init', 9999);
```

### Удаляем всякие wp-json и X-Pingback

В 99 из 100 случаев это просто лишние заголовки и теги в нашей теме. Для того чтоб от них избавиться:

```php
remove_action('wp_head', 'rest_output_link_wp_head', 10);
remove_action('wp_head', 'wp_oembed_add_discovery_links', 10);
remove_action('template_redirect', 'rest_output_link_header', 11, 0);
```

### Убираем со страницы логина логотип WP

Или заменяем на свой - тут уж какая задача стоит:

```php
<?php function make_custom_login_page() { ?>
<style type="text/css">
  div#login_error{width:322px !important}
  body.login div#login h1 {display:block; height:84px;}
  body.login div#login h1 a {display:none !important;}
  p#nav,p#backtoblog{opacity:0.6; transition:all 200ms;}
  p#nav:hover,p#backtoblog:hover{opacity:0.9}
</style>
<?php } ?>

add_action('login_enqueue_scripts', 'make_custom_login_page');
```
