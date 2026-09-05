#include <yaml.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void print_hex(const yaml_char_t *value, size_t length)
{
  size_t index;

  for (index = 0; index < length; ++index) {
    printf("%02x", (unsigned int)value[index]);
  }
}

static void print_nullable(const yaml_char_t *value)
{
  if (value == NULL) {
    printf("-");
  } else {
    printf("%s", value);
  }
}

static int print_event(const yaml_event_t *event)
{
  switch (event->type) {
    case YAML_STREAM_START_EVENT:
      printf("stream-start encoding=%d\n", event->data.stream_start.encoding);
      break;
    case YAML_STREAM_END_EVENT:
      printf("stream-end\n");
      break;
    case YAML_DOCUMENT_START_EVENT:
      printf("document-start implicit=%d", event->data.document_start.implicit);
      if (event->data.document_start.version_directive != NULL) {
        printf(" version=%d.%d",
               event->data.document_start.version_directive->major,
               event->data.document_start.version_directive->minor);
      }
      printf("\n");
      break;
    case YAML_DOCUMENT_END_EVENT:
      printf("document-end implicit=%d\n", event->data.document_end.implicit);
      break;
    case YAML_ALIAS_EVENT:
      printf("alias anchor=");
      print_nullable(event->data.alias.anchor);
      printf("\n");
      break;
    case YAML_SCALAR_EVENT:
      printf("scalar tag=");
      print_nullable(event->data.scalar.tag);
      printf(" style=%d value-hex=",
             event->data.scalar.style);
      print_hex(event->data.scalar.value, event->data.scalar.length);
      printf("\n");
      break;
    case YAML_SEQUENCE_START_EVENT:
      printf("sequence-start tag=");
      print_nullable(event->data.sequence_start.tag);
      printf(" style=%d implicit=%d\n",
             event->data.sequence_start.style,
             event->data.sequence_start.implicit);
      break;
    case YAML_SEQUENCE_END_EVENT:
      printf("sequence-end\n");
      break;
    case YAML_MAPPING_START_EVENT:
      printf("mapping-start tag=");
      print_nullable(event->data.mapping_start.tag);
      printf(" style=%d implicit=%d\n",
             event->data.mapping_start.style,
             event->data.mapping_start.implicit);
      break;
    case YAML_MAPPING_END_EVENT:
      printf("mapping-end\n");
      break;
    default:
      fprintf(stderr, "unexpected libyaml event type: %d\n", event->type);
      return 0;
  }
  return 1;
}

int main(int argc, char **argv)
{
  FILE *input = NULL;
  yaml_event_t event;
  yaml_parser_t parser;
  int parser_initialized = 0;
  int status = EXIT_FAILURE;
  int done = 0;

  if (argc != 2) {
    fprintf(stderr, "usage: %s FIXTURE\n", argv[0]);
    return EXIT_FAILURE;
  }

  input = fopen(argv[1], "rb");
  if (input == NULL) {
    perror(argv[1]);
    return EXIT_FAILURE;
  }

  memset(&parser, 0, sizeof(parser));
  if (!yaml_parser_initialize(&parser)) {
    fprintf(stderr, "could not initialize libyaml parser\n");
    goto cleanup;
  }
  parser_initialized = 1;
  yaml_parser_set_input_file(&parser, input);

  while (!done) {
    memset(&event, 0, sizeof(event));
    if (!yaml_parser_parse(&parser, &event)) {
      fprintf(stderr, "libyaml parse error: %s\n",
              parser.problem != NULL ? parser.problem : "unknown");
      goto cleanup;
    }
    if (!print_event(&event)) {
      yaml_event_delete(&event);
      goto cleanup;
    }
    done = event.type == YAML_STREAM_END_EVENT;
    yaml_event_delete(&event);
  }

  status = EXIT_SUCCESS;

cleanup:
  if (parser_initialized) {
    yaml_parser_delete(&parser);
  }
  fclose(input);
  return status;
}
