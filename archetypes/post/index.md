---
title: {{ replace .Name "-" " " | title }}
slug: {{ replace .Name " " "-" | title | urlize }}
#description: {{ replace .Name "-" " " | title }}
date: {{ .Date }}
expirydate: {{ ((.Date | time ).AddDate 2 6 1).Format "2006-01-02T15:04:05Z07:00" }}
#draft: true
image: cover.jpg
categories: [change_me]
tags: [etc]
---

<!--more-->
