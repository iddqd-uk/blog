---
title: {{ replace .Name "-" " " | title }}
slug: {{ replace .Name " " "-" | title | urlize }}
#description: {{ .Name | title }}
date: {{ .Date }}
#expirydate:
#math: true # enable KaTex, docs: <https://docs.stack.jimmycai.com/configuration/#math>
#license: MIT
hidden: false
#comments: false
#image: cover.jpg # create a file with size 1200x600px
categories: [change_me]
tags:
  - etc
draft: true
---

<!--more-->
