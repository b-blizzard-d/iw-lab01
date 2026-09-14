#!/bin/bash
#
# backup_v4.sh — упаковывает папку в архив .tar.gz с датой в названии.
# Стиль: всё завёрнуто в функции, точка входа — main() в конце файла.

set -euo pipefail

readonly DEFAULT_DEST="/backup"

print_error() {
    echo "[!] $*" >&2
}

print_info() {
    echo "[i] $*"
}

check_args() {
    if [[ $# -lt 1 ]]; then
        print_error "не передана директория-источник."
        print_error "Пример вызова: $0 <откуда> [<куда>]"
        return 1
    fi
    return 0
}

check_source_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        print_error "директория-источник '$dir' не существует."
        return 1
    fi
    return 0
}

ensure_dest_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        print_info "Целевая директория '$dir' не найдена, создаю..."
        if ! mkdir -p "$dir"; then
            print_error "не удалось создать директорию '$dir'."
            return 1
        fi
    fi

    if [[ ! -w "$dir" ]]; then
        print_error "директория '$dir' недоступна для записи."
        return 1
    fi

    return 0
}

make_archive_path() {
    local src="$1" dest="$2"
    local name stamp

    name="$(basename "${src%/}")"
    stamp="$(date +%Y_%m_%d-%H%M)"

    echo "${dest%/}/${name}__${stamp}.tar.gz"
}

create_archive() {
    local src="$1" archive_path="$2"
    local src_clean parent base

    src_clean="${src%/}"
    parent="$(dirname "$src_clean")"
    base="$(basename "$src_clean")"

    print_info "Упаковываю '$src_clean' в '$archive_path'..."

    if tar -czf "$archive_path" -C "$parent" "$base"; then
        print_info "Резервная копия готова: $archive_path"
        return 0
    else
        print_error "во время архивации что-то пошло не так."
        [[ -f "$archive_path" ]] && rm -f "$archive_path"
        return 1
    fi
}

main() {
    local src dest archive_path

    check_args "$@" || exit 1

    src="$1"
    dest="${2:-$DEFAULT_DEST}"

    check_source_dir "$src" || exit 1
    ensure_dest_dir "$dest" || exit 1

    archive_path="$(make_archive_path "$src" "$dest")"

    create_archive "$src" "$archive_path" || exit 1
}

main "$@"
