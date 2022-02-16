---
title: Задачи для лайв-кодинга на Go
slug: interview-section-golang-coding
#description: Go Interview Coding
date: 2022-02-08T06:47:03Z
expirydate: 2027-08-09T06:47:03Z
#draft: true
image: cover.png
categories: [go]
toc: true
tags: [golang, interview, coding]
---

В этой заметки содержатся (и, возможно, будут периодически добавляться) задачи на лайв-кодинг для Go разработчиков, что встречаются на интервью, либо являются хорошими кандидатами для этого.

<!--more-->

## Найти пересечение двух неупорядоченных слайсов любой длины

Перечесение - это те элементы, что присутствуют в обоих слайсах, то есть:

- `f([]int{1, 2, 2, 1}, []int{2, 2}) == []int{2, 2}`
- `f([]int{4, 9, 5}, []int{9, 4, 9, 8, 4}) == []int{4, 9} or []int{9, 4}`

Можно решить сортировкой, за более долгое время, но без выделения дополнительной памяти. А можно выделить дополнительную память и решить за линейное время:

```go
package main

import "fmt"

func intersection(one, two []int) []int {
	var m = make(map[int]uint) // не делаем пре-аллокацию, так как не знаем количество дублей

	for i := range one { // пробегаясь по первому слайсу "прогреваем" карту
    m[one[i]]++ // так как нулевое значение для uint это 0 - то просто увеличиваем
	}

	var result = make([]int, 0) // тоже без пре-аллокации, т.к. не знаем сколько пересечений

	for i := range two { // пробегаясь по второму - ищем пересечение
		if value, ok := m[two[i]]; ok {
			if value > 0 {
				m[two[i]]--
				result = append(result, two[i])
			} else {
				delete(m, two[i]) // прибираемся, так как ключ уже не нужен (== 0)
			}
		}
	}

	return result
}

func main() {
  fmt.Printf("%v\n", intersection([]int{23, 3, 1, 2}, []int{6, 2, 4, 23})) // [2, 23]
  fmt.Printf("%v\n", intersection([]int{1, 1, 1}, []int{1, 1, 1, 1}))      // [1, 1, 1]
}
```

Сложность этого решения получается `O(n+m)` где `n` - это длина первого слайса и `m` второго (сложность вставки в мапу `O(1)`; поиска тоже, чаще всего).

Или вот универсальный вариант, что ищет пересечение в неограниченном количестве слайсов на входе:

```go
package main

import "fmt"

func intersection(in ...[]int) []int {
  var result = make([]int, 0)

  if len(in) < 2 {
    return result
  }

  var longestSliceIdx = 0

  for i := 0; i < len(in); i++ { // находим самый длинный слайс
    if len(in[i]) > len(in[longestSliceIdx]) {
      longestSliceIdx = i
    }
  }

  var m = make([]map[int]uint, len(in)-1) // слайс из мап для счётчиков значений

  for i, j := 0, 0; i < len(in); i++ { // "прогреваем" мапы по каждому полученному слайсу
    if i == longestSliceIdx { // кроме самого длинного
      continue
    }

    m[j] = make(map[int]uint)
    for _, k := range in[i] {
      m[j][k]++
    }

    j++
  }

valuesLoop:
  for _, value := range in[longestSliceIdx] { // проходимся по всем значениям из самого длинного слайса
    for _, mmap := range m { // пробегаемся по всем мапам, что хранят количество вхождений
      if count, ok := mmap[value]; ok { // и если в карте найдено значение из самого длинного слайса
        if count > 0 { // и его счётчик больше нуля
          mmap[value]-- // то уменьшаем его счётчик и НЕ прерываем цикл
        } else { // если значения есть и оно == 0
          delete(mmap, value) // то удаляем его (прибираемся)

          continue valuesLoop // и переходим к следующему значению (не ищем во всех мапах)
        }
      } else {
        continue valuesLoop // если значения в мапе нет, то и в других мапах искать нет смысла
      }

      result = append(result, value)
    }
  }

  return result
}

func main() {
  fmt.Printf("%v\n", intersection([]int{23, 3, 1, 2}, []int{6, 2, 4, 23})) // [23, 2]
  fmt.Printf("%v\n", intersection([]int{1, 1, 1}, []int{1, 1, 1, 1}))      // [1, 1, 1]
  fmt.Printf("%v\n", intersection([]int{1, 2, 2, 1}, []int{2, 2}))         // [2, 2]
  fmt.Printf("%v\n", intersection([]int{4, 9, 5}, []int{9, 4, 9, 8, 4}))   // [9, 4]
}
```

## Написать генератор случайных чисел

Легкая задача, на базовые знания по асинхронному взаимодействию в Go. Главная особенность - не выделять память заранее под случайные числа, так как их могут быть миллионы (в этом же и есть весть смысл генератора). Функция `RandomGen` возвращает канал, в который пишутся случайные сислы и функцию, которая генератор останавливает, освобождая все необходимые ресурсы:

```go
package main

import (
  "math/rand"
  "sync/atomic"
  "time"
)

func RandomGen() (<-chan int, func()) {
  var (
    rnd       = rand.New(rand.NewSource(time.Now().UnixNano()))
    out, exit = make(chan int), make(chan struct{})
    exited    uint32 // atomic usage only
  )

  go func() {
    defer close(out) // уходя гасим за собой свет (закрываем канал)

    for {
      select {
      case <-exit: // закрытие канала exit вызовет этот case
        return

      case out <- rnd.Int(): // пока канал exit не закрыт - отправляем
        // do nothing
      }
    }
  }()

  return out, func() { // вызов функции закроет канал exit
    if old := atomic.SwapUint32(&exited, 1); old == 0 { // защита от повторного вызова
      close(exit)
    }
  }
}

func main() {
  rnd, stop := RandomGen()
  defer stop() // можно вызвать несколько раз - ничего страшного

  for i := 0; i < 3; i++ {
    println(<-rnd) // выведет 3 случайных числа
  }

  stop() // останавливаем генератор

  println(<-rnd, <-rnd) // вернёт дважды 0
}
```

## Алгоритм бинарного (двоичного) поиска

Также известен как метод деления пополам или дихотомия - классический алгоритм поиска элемента в отсортированном массиве (слайсе), использующий дробление массива (слайса) на половины. У нас на входе может быть слайс вида `[]int{1, 3, 4, 6, 8, 10, 55, 56, 59, 70, 79, 81, 91, 10001}`, и нужно вернуть индекс числа `55` (результат будет `6 true`):

```go
func BinarySearch(in []int, searchFor int) (int, bool) {
	if len(in) == 0 {
		return 0, false
	}

	var first, last = 0, len(in) - 1

	for first <= last {
		var mid = ((last - first) / 2) + first

		if in[mid] == searchFor {
			return mid, true
		} else if in[mid] > searchFor { // нужно искать в "левой" части слайса
			last = mid - 1
		} else if in[mid] < searchFor { // нужно искать в "правой" части слайса
			first = mid + 1
		}
	}

	return 0, false
}
```


## Обход ссылок из файла

Дан некоторый файл, в котором содержатся HTTP ссылки на различные ресурсы. Нужно реализовать обход всех этих ссылок, и вывести в терминал `OK` в случае `200`-го кода ответа, и `Not OK` в противном случае. Засучаем рукава и в бой, пишем наивный вариант (читаем файл в память, и итерируем слайс ссылок):

```go
package main

import (
  "bufio"
  "context"
  "net/http"
  "os"
  "strings"
  "time"
)

func main() {
  if err := run(); err != nil {
    println(err.Error())

    os.Exit(1)
  }
}

func run() error {
  var ctx = context.Background()

  // открываем файл
  f, err := os.Open("links_list.txt")
  if err != nil {
    return err
  }
  defer func() { _ = f.Close() }()

  // читаем файл построчно
  var scan = bufio.NewScanner(f)
  for scan.Scan() {
    var url = strings.TrimSpace(scan.Text())

    if ok, fetchErr := fetchLink(ctx, http.MethodGet, url); fetchErr != nil {
      return fetchErr
    } else {
      if ok {
        println("OK", url)
      } else {
        println("Not OK", url)
      }
    }
  }

  // проверяем сканер на наличие ошибок
  if err = scan.Err(); err != nil {
    return err
  }

  return nil
}

// объявляем HTTP клиент для переиспользования
var httpClient = http.Client{Timeout: time.Second * 5}

func fetchLink(ctx context.Context, method, url string) (bool, error) {
  // создаём объект запроса
  var req, err = http.NewRequestWithContext(ctx, method, url, http.NoBody)
  if err != nil {
    return false, err
  }

  // выполняем его
  resp, err := httpClient.Do(req)
  if err != nil {
    return false, err
  }

  // валидируем статус код
  if resp.StatusCode == http.StatusOK {
    return true, nil
  }

  return false, nil
}
```

Файл со списком ссылок (`links_list.txt`):

```text
https://www.yahoo.com/foobar
https://stackoverflow.com/foobar
https://blog.hook.sh/
https://google.com/404error
https://ya.ru/
https://github.com/foo/bar
https://stackoverflow.com/
```

Запускаем код (`go run .`), видим результат:

```text
Not OK https://www.yahoo.com/foobar
Not OK https://stackoverflow.com/foobar
OK https://blog.hook.sh/
Not OK https://google.com/404error
OK https://ya.ru/
Not OK https://github.com/foo/bar
OK https://stackoverflow.com/
```

И тут интервьювер обновляет постановку задачи - нужно выполнять работу асинхронно. И сделать так, чтоб после получения **двух** `OK` останавливать всю работу, отменяя уже отправленные запросы. Приводим свой код в соответствие, используя каналы по-максимуму:

```go
package main

import (
  "bufio"
  "context"
  "errors"
  "net/http"
  "os"
  "strings"
  "time"
)

func main() {
  if err := run(); err != nil {
    println("Fatal error:", err.Error())

    os.Exit(1)
  }
}

type result struct { // объявляем структуру для описания результата опроса URL
  url string
  ok  bool
}

func run() error {
  var ctx, cancel = context.WithCancel(context.Background()) // заменяем контекст на контекст с отменой
  defer cancel()

  f, err := os.Open("links_list.txt")
  if err != nil {
    return err
  }
  defer func() { _ = f.Close() }()

  var urlsCh, errCh, resultsCh = make(chan string), make(chan error), make(chan result) // объявляем каналы для работы
  defer func() { close(errCh); close(resultsCh) }()

  go func() { // читаем файл построчно в отдельной горутине и пишем в каналы (запускаем "планировщик")
    defer close(urlsCh) // не забываем закрыть канал (когда список кончится или контекст отменится)

    var scan = bufio.NewScanner(f)
    for scan.Scan() {
      select {
      case <-ctx.Done(): // проверяем контекст на факт его отмены
        return

      default:
        if url := strings.TrimSpace(scan.Text()); url != "" {
          urlsCh <- url // и пишем в канал для ссылок по одной
        }
      }
    }

    if err = scan.Err(); err != nil {
      errCh <- err
    }
  }()

  const workersCount uint8 = 4 // объявляем константу с количеством "воркеров"

  var progress, done = make(chan struct{}), make(chan struct{}) // каналы для сообщений о ходе работы и её завершении
  defer close(done)

  go func() { // запускаем горутину, что будет N раз ничего не делать, а по завершении запишет в канал done
    for i := uint8(0); i < workersCount; i++ {
      <-progress
    }

    close(progress)

    done <- struct{}{}
  }()

  for i := uint8(0); i < workersCount; i++ { // запускаем горутины для выполнения HTTP запросов
    go func() {
      defer func() { progress <- struct{}{} }() // когда она завершится, то запишет в канал progress

      for {
        select {
        case <-ctx.Done(): // так же проверяем контекст на факт его отмены
          return

        case url, isOpened := <-urlsCh: // и читаем из канала для ссылок
          if !isOpened { // если он закрыт нашим "планировщиком"
            return // то выходим
          }

          if ok, fetchErr := fetchLink(ctx, http.MethodGet, url); fetchErr != nil {
            errCh <- fetchErr
          } else if ctx.Err() == nil { // дополнительно проверяем контекст
            resultsCh <- result{url: url, ok: ok} // результаты пишем в канал для ответов
          }
        }
      }
    }()
  }

  var (
    okCounter uint  // счётчик успешных запросов
    lastError error // переменная для последней "пойманной" ошибки
  )

loop:
  for {
    select {
    case workingErr, isOpened := <-errCh: // если пришла ошибка (при чтении файла или HTTP)
      if isOpened && !errors.Is(workingErr, context.Canceled) { // игнорируем ошибку "отмены контекста"
        lastError = workingErr // то сохраняем её в lastError
        cancel()               // и отменяем контекст (чтоб горутины завершились) но не прерываем цикл
      }

    case res := <-resultsCh: // если пришел результат от воркера
      if res.ok {
        okCounter++
        println("OK", res.url)
      } else {
        println("Not OK", res.url)
      }

      if okCounter >= 2 { // а вот как раз и наше условие для отмены
        cancel()
      }

    case <-done: // и выход из цикла обязательно должен осуществится после сообщения в done
      println("work is done")

      break loop // только тут прерываем цикл, так как горутины все вышли и никто не напишет в закрытые каналы
    }
  }

  return lastError
}

// объявляем HTTP клиент для переиспользования
var httpClient = http.Client{Timeout: time.Second * 5}

func fetchLink(ctx context.Context, method, url string) (bool, error) {
  // создаём объект запроса
  var req, err = http.NewRequestWithContext(ctx, method, url, http.NoBody)
  if err != nil {
    return false, err
  }

  // выполняем его
  resp, err := httpClient.Do(req)
  if err != nil {
    return false, err
  }

  // валидируем статус код
  if resp.StatusCode == http.StatusOK {
    return true, nil
  }

  return false, nil
}
```
