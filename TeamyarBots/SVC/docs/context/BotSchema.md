# Bot Schema (extract)

Schema: 0000000
Only bot-platform tables. For other tables use `db_schema_json_bot.lua`.

## bot_command

| Column | Type | Key |
|--------|------|-----|
| ID | bigint | PRI |
| NAME | varchar(200) |  |
| DESCRIPTION | text |  |
| COMMAND | mediumtext |  |
| FORM_SETTING | text |  |
| RESULT_TYPE | int |  |
| PERIOD_TIME | int |  |
| PERIOD_DAY | bigint |  |
| PERIOD_START | bigint |  |
| TIMER_FORM_VAL | text |  |
| MODIFY_DATE | bigint |  |
| MODIFIER | bigint |  |
| src_command_id | bigint |  |
| src_domain | varchar(200) |  |
| folder_id | bigint |  |
| public_access | int |  |
| not_showing_in_iframe | int |  |
| run_path | varchar(200) |  |
| icon | varchar(20) |  |
| color | varchar(20) |  |
| show_in_portal_menu | int |  |
| src_creator | varchar(200) |  |
| document_id | bigint |  |
| db_prefix | varchar(100) |  |
| async_run | int |  |
| async_deadline_run | int |  |
| check_table_flag | int |  |
| disabled | int |  |
| BYTECODE_COMMAND | mediumtext |  |
| open_source | int |  |
| show_in_widget | int |  |
| max_execute_time | int |  |
| cache_time | int |  |
| max_version | int |  |
| document_content | text |  |
| src_version | int |  |
| bot_config | json |  |
| help_content | text |  |
| default_db | bigint |  |

## bot_command_run

| Column | Type | Key |
|--------|------|-----|
| COMMAND_ID | bigint | PRI |
| RUN_COUNT | bigint |  |

## bot_command_version

| Column | Type | Key |
|--------|------|-----|
| COMMAND_ID | bigint | PRI |
| COMMAND_VERSION | int | PRI |
| ACTIVE_VERSION | smallint |  |
| DB_PREFIX | varchar(100) |  |
| DESCRIPTION | text |  |
| COMMAND | mediumtext |  |
| BYTECODE_COMMAND | mediumtext |  |
| FORM_SETTING | text |  |
| DOCUMENT_CONTENT | text |  |
| MAX_EXECUTE_TIME | int |  |
| RESULT_TYPE | int |  |
| NOT_SHOWING_IN_IFRAME | int |  |
| ASYNC_RUN | int |  |
| ASYNC_DEADLINE_RUN | int |  |
| CHECK_TABLE_FLAG | int |  |
| TIMER_FORM_VAL | text |  |
| MODIFY_DATE | bigint |  |
| MODIFIER | bigint |  |
| CACHE_TIME | int |  |
| bot_config | json |  |
| help_content | text |  |

## bot_command_files

| Column | Type | Key |
|--------|------|-----|
| ID | bigint | PRI |
| COMMAND_ID | bigint | MUL |
| COMMAND_VERSION | int |  |
| FILE_ID | bigint |  |
| FILE_RECORD_TYPE | smallint |  |
| FILE_NAME | varchar(400) |  |

## bot_history

| Column | Type | Key |
|--------|------|-----|
| ID | bigint | PRI |
| RUN_ID | bigint |  |
| FLAG | int |  |
| CONTENT | text |  |
| DATE_CREATE | bigint |  |
| command_id | bigint |  |
| run_type | int |  |
| author_id | bigint |  |
| running_time | bigint |  |
| command_version | int |  |

## bot_param

| Column | Type | Key |
|--------|------|-----|
| ID | bigint | PRI |
| REF_ID | bigint |  |
| NAME | varchar(200) |  |
| VALUE | text |  |
| MODIFY_DATE | bigint |  |
| MODIFIER | bigint |  |

## bot_command_categories

| Column | Type | Key |
|--------|------|-----|
| COMMAND_ID | bigint | PRI |
| CAT_ID | bigint | PRI |
| IS_DEFAULT | int |  |

