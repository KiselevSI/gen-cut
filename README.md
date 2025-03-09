
# Извлечение подпоследовательностей из геномных файлов

Этот bash-скрипт предназначен для извлечения подпоследовательностей из геномных файлов в формате `.fna.gz` на основе координат, указанных в TSV-файле. Скрипт поддерживает параллельную обработку для ускорения работы и может извлекать как прямые, так и обратные комплементарные последовательности.

## Назначение

Скрипт позволяет автоматизировать процесс извлечения подпоследовательностей из больших геномных файлов, используя идентификаторы и координаты из TSV-файла. Он полезен для биоинформатических задач, связанных с анализом геномных данных.

## Зависимости

Для работы скрипта требуются следующие утилиты:

- **[seqkit](https://bioinf.shenwei.me/seqkit/)**: Инструмент для работы с последовательностями в формате FASTA/Q.
- **[GNU Parallel](https://www.gnu.org/software/parallel/)**: Для параллельной обработки строк TSV-файла (опционально, но рекомендуется для повышения производительности).

Убедитесь, что обе утилиты установлены и доступны в вашем `PATH`.

## Установка

### Установка seqkit

```bash
# Для Ubuntu/Debian
sudo apt-get install seqkit

# Для macOS с Homebrew
brew install brewsci/bio/seqkit

# Или скачайте бинарный файл с сайта: https://bioinf.shenwei.me/seqkit/download/
```

### Установка GNU Parallel (опционально)

```bash
# Для Ubuntu/Debian
sudo apt-get install parallel

# Для macOS с Homebrew
brew install parallel
```

## Использование

Скрипт запускается из командной строки с обязательными и опциональными параметрами:

```bash
./extract_sequences.sh -i <tsv_file> -g <genome_dir> -o <output_dir> [-t <threads>]
```

### Параметры

- `-i <tsv_file>`: Путь к TSV-файлу с координатами (обязательный).
- `-g <genome_dir>`: Путь к директории с геномными файлами `.fna.gz` (обязательный).
- `-o <output_dir>`: Путь к директории для сохранения результатов (обязательный).
- `-t <threads>`: Количество параллельных процессов (опциональный, по умолчанию: 4).

Если обязательные параметры не указаны, скрипт выведет сообщение об ошибке и инструкцию по использованию.

## Формат входных данных

### TSV-файл

TSV-файл должен быть разделён символами табуляции и содержать три колонки без заголовка:

1. **id**: Идентификатор последовательности, который должен присутствовать в заголовке геномного файла.
2. **start**: Начальная позиция подпоследовательности (целое число).
3. **end**: Конечная позиция подпоследовательности (целое число).

**Примечание**: Если `start` больше `end`, скрипт извлечёт обратную комплементарную последовательность.

Пример `coordinates.tsv`:
```
contig1	100	200
contig2	300	150
```

### Геномные файлы

Геномные файлы должны быть в формате `.fna.gz` (сжатые FASTA-файлы). Заголовки в этих файлах должны содержать идентификатор `id` из TSV-файла. Скрипт ищет точное совпадение заголовка для извлечения подпоследовательности.

## Выходные данные

Для каждой строки TSV-файла скрипт создаёт FASTA-файл в указанной выходной директории с именем в формате `${id}_${start}_${end}.fasta`. Если извлекается обратная комплементарная последовательность (когда `start` > `end`), порядок координат в имени файла сохраняется как в TSV-файле (например, `contig2_300_150.fasta`).

## Примеры

### Пример 1: Извлечение прямой последовательности

Допустим, у вас есть TSV-файл `coordinates.tsv`:
```
contig1	100	200
```

И директория `genomes/` с файлом `genome1.fna.gz`, содержащим последовательность с заголовком `>contig1`.

Команда:
```bash
./extract_sequences.sh -i coordinates.tsv -g genomes/ -o output/
```

Результат: В директории `output/` появится файл `contig1_100_200.fasta` с подпоследовательностью от 100 до 200 позиции.

### Пример 2: Извлечение обратной комплементарной последовательности

TSV-файл `coordinates.tsv`:
```
contig2	300	150
```

Команда:
```bash
./extract_sequences.sh -i coordinates.tsv -g genomes/ -o output/ -t 2
```

Результат: В директории `output/` появится файл `contig2_300_150.fasta`, содержащий обратную комплементарную последовательность от 150 до 300 позиции, обработанную с использованием двух потоков.

## Обработка ошибок

Скрипт выводит сообщения об ошибках в `stderr` в следующих случаях:

- **Файл `.fna.gz` не найден для указанного `id`**.
- **Заголовок с `id` не найден в геномном файле**.
- **Ошибка выполнения `seqkit`**.

Пример вывода ошибки:
```
Ошибка: файл не найден для ID: contig3
Ошибка: заголовок не найден для ID: contig4 в файле genomes/genome1.fna.gz
Ошибка: seqkit не смог обработать ID: contig5
```

Проверьте входные данные и убедитесь, что все файлы и идентификаторы корректны.

## Дополнительные замечания

- Убедитесь, что в TSV-файле нет лишних пробелов или символов возврата каретки (`\r`), так как это может повлиять на чтение строк.
- Если параллельная обработка не нужна, используйте `-t 1`.
- Для больших наборов данных увеличьте количество потоков (`-t`), чтобы ускорить выполнение.



---

Этот README предоставляет полное описание скрипта, инструкции по установке и использованию, а также примеры, которые помогут пользователям быстро начать работу с вашим инструментом. Если у вас есть дополнительные пожелания или нужно что-то изменить, дайте знать!
