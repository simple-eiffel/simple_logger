note
	description: "[
		Simple Logger - Enhanced logging facade with structured fields and JSON output.

		Wraps Eiffel's LOG_LOGGING_FACILITY with a cleaner API and adds:
		- Structured key-value fields
		- JSON output format (via simple_json)
		- Enter/exit tracing with indentation
		- Child loggers with inherited context
		- Duration/timer logging

		Usage:
			create log.make
			log.info ("Application started")
			log.info_with ("User logged in", << ["user_id", "123"], ["action", "login"] >>)

		JSON Output:
			log.set_json_output (True)
			-- {"timestamp":"2025-12-06T14:30:00","level":"info","message":"Started"}
	]"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=RFC 5424 Syslog", "src=https://tools.ietf.org/html/rfc5424", "protocol=URI"

class
	SIMPLE_LOGGER

inherit
	ANY
		redefine
			default_create
		end

create
	default_create,
	make,
	make_with_level,
	make_to_file,
	make_child

feature {NONE} -- Initialization

	default_create
			-- Create logger with INFO level, console output.
		do
			make
		end

	make
			-- Create logger with INFO level, console output.
		do
			level := Level_info
			is_console_output := True
			is_json_output := False
			create context_fields.make (5)
			create eiffel_facility.make
			setup_console_writer
		ensure
			level_is_info: level = Level_info
			outputs_to_console: is_console_output
			not_json: not is_json_output
		end

	make_with_level (a_level: INTEGER)
			-- Create logger with specified level, console output.
		require
			valid_level: a_level >= Level_debug and a_level <= Level_fatal
		do
			make
			level := a_level
		ensure
			level_set: level = a_level
			outputs_to_console: is_console_output
		end

	make_to_file (a_path: STRING)
			-- Create logger outputting to file.
		require
			path_not_empty: not a_path.is_empty
		do
			make
			is_console_output := False
			is_file_output := True
			file_path := a_path
			setup_file_writer (a_path)
		ensure
			outputs_to_file: is_file_output
			file_path_set: attached file_path as fp and then fp.same_string (a_path)
		end

	make_child (a_parent: SIMPLE_LOGGER; a_context: HASH_TABLE [ANY, STRING])
			-- Create child logger inheriting parent's settings and context.
		require
			parent_not_void: a_parent /= Void
			context_not_void: a_context /= Void
		do
			level := a_parent.level
			is_console_output := a_parent.is_console_output
			is_file_output := a_parent.is_file_output
			is_json_output := a_parent.is_json_output
			file_path := a_parent.file_path
			eiffel_facility := a_parent.eiffel_facility
			-- Merge parent context with new context
			create context_fields.make (a_parent.context_fields.count + a_context.count)
			from
				a_parent.context_fields.start
			until
				a_parent.context_fields.off
			loop
				context_fields.put (a_parent.context_fields.item_for_iteration, a_parent.context_fields.key_for_iteration)
				a_parent.context_fields.forth
			end
			from
				a_context.start
			until
				a_context.off
			loop
				context_fields.force (a_context.item_for_iteration, a_context.key_for_iteration)
				a_context.forth
			end
		ensure
			inherits_level: level = a_parent.level
			has_context: context_fields.count >= a_context.count
		end

feature -- Log Levels (Constants)

	Level_debug: INTEGER = 1
			-- Debug level (most verbose).

	Level_info: INTEGER = 2
			-- Informational level.

	Level_warn: INTEGER = 3
			-- Warning level.

	Level_error: INTEGER = 4
			-- Error level.

	Level_fatal: INTEGER = 5
			-- Fatal level (most severe).

feature -- Access

	level: INTEGER
			-- Current minimum log level.

	is_console_output: BOOLEAN
			-- Is outputting to console?

	is_file_output: BOOLEAN
			-- Is outputting to file?

	is_json_output: BOOLEAN
			-- Is using JSON format?

	file_path: detachable STRING
			-- Path to log file (if file output enabled).

	context_fields: HASH_TABLE [ANY, STRING]
			-- Fields inherited by this logger (from parent or set directly).

feature -- Configuration

	set_level,
	set_log_level,
	configure_level (a_level: INTEGER)
			-- Set minimum log level.
		require
			valid_level: a_level >= Level_debug and a_level <= Level_fatal
		do
			level := a_level
		ensure
			level_set: level = a_level
		end

	set_json_output (a_enabled: BOOLEAN)
			-- Enable/disable JSON formatted output.
		do
			is_json_output := a_enabled
		ensure
			json_set: is_json_output = a_enabled
		end

	add_context,
	set_field,
	with_field (a_key: STRING; a_value: ANY)
			-- Add a context field that appears in all subsequent logs.
		require
			key_not_empty: not a_key.is_empty
		do
			context_fields.force (a_value, a_key)
		ensure
			field_added: context_fields.has (a_key)
		end

	add_file_output (a_path: STRING)
			-- Add file output in addition to current outputs.
		require
			path_not_empty: not a_path.is_empty
		do
			is_file_output := True
			file_path := a_path
			setup_file_writer (a_path)
		ensure
			file_output_enabled: is_file_output
		end

feature -- Logging (Simple)

	debug_log,
	trace,
	verbose (a_message: STRING)
			-- Log debug message.
		require
			message_not_void: a_message /= Void
		do
			log_at_level (Level_debug, a_message, Void)
		end

	info,
	log,
	log_info,
	message (a_message: STRING)
			-- Log info message.
		require
			message_not_void: a_message /= Void
		do
			log_at_level (Level_info, a_message, Void)
		end

	warn,
	warning,
	log_warn (a_message: STRING)
			-- Log warning message.
		require
			message_not_void: a_message /= Void
		do
			log_at_level (Level_warn, a_message, Void)
		end

	error,
	log_error,
	err (a_message: STRING)
			-- Log error message.
		require
			message_not_void: a_message /= Void
		do
			log_at_level (Level_error, a_message, Void)
		end

	fatal (a_message: STRING)
			-- Log fatal message.
		require
			message_not_void: a_message /= Void
		do
			log_at_level (Level_fatal, a_message, Void)
		end

feature -- Logging (Structured with HASH_TABLE)

	debug_with (a_message: STRING; a_fields: HASH_TABLE [ANY, STRING])
			-- Log debug with structured fields.
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_debug, a_message, a_fields)
		end

	info_with (a_message: STRING; a_fields: HASH_TABLE [ANY, STRING])
			-- Log info with structured fields.
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_info, a_message, a_fields)
		end

	warn_with (a_message: STRING; a_fields: HASH_TABLE [ANY, STRING])
			-- Log warning with structured fields.
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_warn, a_message, a_fields)
		end

	error_with (a_message: STRING; a_fields: HASH_TABLE [ANY, STRING])
			-- Log error with structured fields.
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_error, a_message, a_fields)
		end

	fatal_with (a_message: STRING; a_fields: HASH_TABLE [ANY, STRING])
			-- Log fatal with structured fields.
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_fatal, a_message, a_fields)
		end

feature -- Logging (Structured with ARRAY convenience)

	info_fields (a_message: STRING; a_fields: ARRAY [TUPLE [key: STRING; value: ANY]])
			-- Log info with fields as array of tuples (convenience).
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_info, a_message, tuple_array_to_hash (a_fields))
		end

	error_fields (a_message: STRING; a_fields: ARRAY [TUPLE [key: STRING; value: ANY]])
			-- Log error with fields as array of tuples (convenience).
		require
			message_not_void: a_message /= Void
			fields_not_void: a_fields /= Void
		do
			log_at_level (Level_error, a_message, tuple_array_to_hash (a_fields))
		end

feature -- Child Loggers

	child (a_context: HASH_TABLE [ANY, STRING]): SIMPLE_LOGGER
			-- Create child logger with inherited context.
			-- All logs from child will include parent's context fields.
		require
			context_not_void: a_context /= Void
		do
			create Result.make_child (Current, a_context)
		ensure
			inherits_level: Result.level = level
		end

	child_with (a_key: STRING; a_value: ANY): SIMPLE_LOGGER
			-- Create child logger with single context field (convenience).
		require
			key_not_empty: not a_key.is_empty
		local
			l_context: HASH_TABLE [ANY, STRING]
		do
			create l_context.make (1)
			l_context.put (a_value, a_key)
			Result := child (l_context)
		end

feature -- Tracing (Enter/Exit)

	enter (a_feature_name: STRING)
			-- Log entering a feature (for call tracing).
		require
			feature_name_not_empty: not a_feature_name.is_empty
		local
			l_fields: HASH_TABLE [ANY, STRING]
		do
			create l_fields.make (1)
			l_fields.put ("enter", "trace")
			log_at_level (Level_debug, ">>> " + a_feature_name, l_fields)
			increment_indent
		end

	exit (a_feature_name: STRING)
			-- Log exiting a feature (for call tracing).
		require
			feature_name_not_empty: not a_feature_name.is_empty
		local
			l_fields: HASH_TABLE [ANY, STRING]
		do
			decrement_indent
			create l_fields.make (1)
			l_fields.put ("exit", "trace")
			log_at_level (Level_debug, "<<< " + a_feature_name, l_fields)
		end

feature -- Timing

	start_timer: SIMPLE_LOG_TIMER
			-- Start a timer for measuring duration.
		do
			create Result.make
		ensure
			timer_started: Result /= Void
		end

	log_duration (a_timer: SIMPLE_LOG_TIMER; a_message: STRING)
			-- Log info message with duration from timer.
		require
			timer_not_void: a_timer /= Void
			message_not_void: a_message /= Void
		local
			l_fields: HASH_TABLE [ANY, STRING]
		do
			create l_fields.make (1)
			l_fields.put (a_timer.elapsed_ms, "duration_ms")
			log_at_level (Level_info, a_message, l_fields)
		end

feature {SIMPLE_LOGGER} -- Implementation (shared with child loggers)

	eiffel_facility: LOG_LOGGING_FACILITY
			-- Underlying Eiffel logging facility.

	console_writer: detachable LOG_WRITER_FILE
			-- Console output writer.

	file_writer: detachable LOG_WRITER_FILE
			-- File output writer.

	indent_level: INTEGER
			-- Current indentation level for tracing.

	setup_console_writer
			-- Set up console output writer.
		do
			-- Use stdout via Eiffel facility
			-- Note: LOG_LOGGING_FACILITY writes to registered writers
		end

	setup_file_writer (a_path: STRING)
			-- Set up file output writer.
		require
			path_not_empty: not a_path.is_empty
		local
			l_writer: LOG_WRITER_FILE
			l_path: PATH
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_path.make_from_string (a_path)
				create l_writer.make_at_location (l_path)
				l_writer.enable_debug_log_level
				eiffel_facility.register_log_writer (l_writer)
				file_writer := l_writer
			end
		rescue
			l_retried := True
			retry
		end

	log_at_level (a_level: INTEGER; a_message: STRING; a_fields: detachable HASH_TABLE [ANY, STRING])
			-- Core logging routine.
		require
			valid_level: a_level >= Level_debug and a_level <= Level_fatal
			message_not_void: a_message /= Void
		local
			l_output: STRING
			l_all_fields: HASH_TABLE [ANY, STRING]
		do
			-- Check if we should log at this level
			if a_level >= level then
				-- Merge context fields with provided fields
				create l_all_fields.make (context_fields.count + (if a_fields /= Void then a_fields.count else 0 end))
				from
					context_fields.start
				until
					context_fields.off
				loop
					l_all_fields.put (context_fields.item_for_iteration, context_fields.key_for_iteration)
					context_fields.forth
				end
				if a_fields /= Void then
					from
						a_fields.start
					until
						a_fields.off
					loop
						l_all_fields.force (a_fields.item_for_iteration, a_fields.key_for_iteration)
						a_fields.forth
					end
				end

				-- Format output
				if is_json_output then
					l_output := format_json (a_level, a_message, l_all_fields)
				else
					l_output := format_plain (a_level, a_message, l_all_fields)
				end

				-- Output to console
				if is_console_output then
					print (l_output)
					print ("%N")
					io.output.flush
				end

				-- Output to file via Eiffel facility
				if is_file_output and attached file_writer then
					write_to_file (l_output)
				end
			end
		end

	format_plain (a_level: INTEGER; a_message: STRING; a_fields: HASH_TABLE [ANY, STRING]): STRING
			-- Format log entry as plain text.
		local
			l_time: DATE_TIME
			i: INTEGER
		do
			create Result.make (200)

			-- Timestamp
			create l_time.make_now
			Result.append (l_time.formatted_out ("yyyy-[0]mm-[0]dd [0]hh:[0]mi:[0]ss"))
			Result.append (" ")

			-- Level
			Result.append (level_name (a_level))
			Result.append (" ")

			-- Indentation
			from i := 1 until i > indent_level loop
				Result.append ("  ")
				i := i + 1
			end

			-- Message
			Result.append (a_message)

			-- Fields
			if not a_fields.is_empty then
				Result.append (" ")
				from
					a_fields.start
				until
					a_fields.off
				loop
					Result.append (a_fields.key_for_iteration)
					Result.append ("=")
					if attached {STRING} a_fields.item_for_iteration as s then
						Result.append (s)
					else
						Result.append (a_fields.item_for_iteration.out)
					end
					Result.append (" ")
					a_fields.forth
				end
			end
		ensure
			not_empty: not Result.is_empty
		end

	format_json (a_level: INTEGER; a_message: STRING; a_fields: HASH_TABLE [ANY, STRING]): STRING
			-- Format log entry as JSON using SIMPLE_JSON_OBJECT fluent builder.
			-- Leverages simple_json for proper escaping and type handling.
		local
			l_time: DATE_TIME
			l_json: SIMPLE_JSON_OBJECT
			l_timestamp: STRING
		do
			create l_json.make

			-- Timestamp (ISO 8601)
			create l_time.make_now
			create l_timestamp.make (25)
			l_timestamp.append (l_time.formatted_out ("yyyy-[0]mm-[0]dd"))
			l_timestamp.append ("T")
			l_timestamp.append (l_time.formatted_out ("[0]hh:[0]mi:[0]ss"))
			l_timestamp.append ("Z")

			-- Build JSON using fluent API - chain calls, handles all escaping automatically
			l_json := l_json.put_string (l_timestamp, "timestamp")
			l_json := l_json.put_string (level_name (a_level).as_lower, "level")
			l_json := l_json.put_string (a_message, "message")

			-- Add all fields with proper type handling
			from
				a_fields.start
			until
				a_fields.off
			loop
				if attached {STRING} a_fields.item_for_iteration as s then
					l_json := l_json.put_string (s, a_fields.key_for_iteration)
				elseif attached {STRING_32} a_fields.item_for_iteration as s32 then
					l_json := l_json.put_string (s32, a_fields.key_for_iteration)
				elseif attached {INTEGER} a_fields.item_for_iteration as i then
					l_json := l_json.put_integer (i.to_integer_64, a_fields.key_for_iteration)
				elseif attached {INTEGER_64} a_fields.item_for_iteration as i64 then
					l_json := l_json.put_integer (i64, a_fields.key_for_iteration)
				elseif attached {REAL_64} a_fields.item_for_iteration as r then
					l_json := l_json.put_real (r, a_fields.key_for_iteration)
				elseif attached {REAL_32} a_fields.item_for_iteration as r32 then
					l_json := l_json.put_real (r32.to_double, a_fields.key_for_iteration)
				elseif attached {BOOLEAN} a_fields.item_for_iteration as b then
					l_json := l_json.put_boolean (b, a_fields.key_for_iteration)
				else
					-- Fall back to string representation for other types
					l_json := l_json.put_string (a_fields.item_for_iteration.out, a_fields.key_for_iteration)
				end
				a_fields.forth
			end

			Result := l_json.as_json
		ensure
			not_empty: not Result.is_empty
			valid_json: Result.starts_with ("{")
		end

	level_name (a_level: INTEGER): STRING
			-- Human-readable name for level.
		do
			inspect a_level
			when Level_debug then
				Result := "DEBUG"
			when Level_info then
				Result := "INFO"
			when Level_warn then
				Result := "WARN"
			when Level_error then
				Result := "ERROR"
			when Level_fatal then
				Result := "FATAL"
			else
				Result := "UNKNOWN"
			end
		ensure
			not_empty: not Result.is_empty
		end
	write_to_file (a_message: STRING)
			-- Write message to log file.
		local
			l_file: PLAIN_TEXT_FILE
			l_retried: BOOLEAN
		do
			if not l_retried and then attached file_path as fp then
				create l_file.make_open_append (fp)
				if l_file.is_open_write then
					l_file.put_string (a_message)
					l_file.put_new_line
					l_file.flush
					l_file.close
				end
			end
		rescue
			l_retried := True
			retry
		end


	tuple_array_to_hash (a_tuples: ARRAY [TUPLE [key: STRING; value: ANY]]): HASH_TABLE [ANY, STRING]
			-- Convert array of tuples to hash table.
		local
			i: INTEGER
			l_tuple: TUPLE [key: STRING; value: ANY]
		do
			create Result.make (a_tuples.count)
			from
				i := a_tuples.lower
			until
				i > a_tuples.upper
			loop
				l_tuple := a_tuples [i]
				Result.put (l_tuple.value, l_tuple.key)
				i := i + 1
			end
		end

	increment_indent
			-- Increase indent level.
		do
			indent_level := indent_level + 1
		end

	decrement_indent
			-- Decrease indent level.
		do
			if indent_level > 0 then
				indent_level := indent_level - 1
			end
		end

invariant
	valid_level: level >= Level_debug and level <= Level_fatal
	context_not_void: context_fields /= Void
	facility_not_void: eiffel_facility /= Void
	non_negative_indent: indent_level >= 0

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
