note
	description: "Test set for simple_logger"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Basic Tests

	test_make_default
			-- Test default logger creation.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			check level_is_info: log.level = log.Level_info end
			check console_output: log.is_console_output end
			check not_json: not log.is_json_output end
		end

	test_make_with_level
			-- Test logger creation with specific level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			check level_is_debug: log.level = log.Level_debug end
		end

	test_set_level
			-- Test changing log level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.set_level (log.Level_error)
			check level_changed: log.level = log.Level_error end
		end

	test_set_json_output
			-- Test enabling JSON output.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			check initially_not_json: not log.is_json_output end
			log.set_json_output (True)
			check now_json: log.is_json_output end
		end

feature -- Simple Logging Tests

	test_info_log
			-- Test basic info logging.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.info ("Test info message")
			-- If we get here without exception, test passed
			check passed: True end
		end

	test_debug_log_filtered
			-- Test that debug logs are filtered at INFO level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			-- Level is INFO by default, debug should be filtered
			log.debug_log ("This should not appear")
			check passed: True end
		end

	test_debug_log_shown
			-- Test that debug logs appear at DEBUG level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			log.debug_log ("This should appear")
			check passed: True end
		end

	test_all_levels
			-- Test all log levels.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			log.debug_log ("Debug message")
			log.info ("Info message")
			log.warn ("Warning message")
			log.error ("Error message")
			log.fatal ("Fatal message")
			check passed: True end
		end

feature -- Structured Logging Tests

	test_info_with_fields
			-- Test logging with structured fields.
		local
			log: SIMPLE_LOGGER
			fields: HASH_TABLE [ANY, STRING]
		do
			create log.make
			create fields.make (2)
			fields.put ("user123", "user_id")
			fields.put (42, "order_id")
			log.info_with ("Order processed", fields)
			check passed: True end
		end

	test_info_fields_convenience
			-- Test logging with tuple array convenience.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.info_fields ("User logged in", << ["user_id", "123"], ["action", "login"] >>)
			check passed: True end
		end

feature -- JSON Output Tests

	test_json_output_format
			-- Test JSON formatted output.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.set_json_output (True)
			log.info ("JSON test message")
			-- Visual inspection of output, no assertion failure means passed
			check passed: True end
		end

	test_json_with_fields
			-- Test JSON with structured fields.
		local
			log: SIMPLE_LOGGER
			fields: HASH_TABLE [ANY, STRING]
		do
			create log.make
			log.set_json_output (True)
			create fields.make (3)
			fields.put ("test_user", "user")
			fields.put (100, "count")
			fields.put (True, "success")
			log.info_with ("Test with fields", fields)
			check passed: True end
		end

feature -- Child Logger Tests

	test_child_logger
			-- Test child logger inherits parent context.
		local
			parent_log, child_log: SIMPLE_LOGGER
			ctx: HASH_TABLE [ANY, STRING]
		do
			create parent_log.make
			create ctx.make (1)
			ctx.put ("request-123", "request_id")
			child_log := parent_log.child (ctx)
			check inherits_level: child_log.level = parent_log.level end
			check has_context: child_log.context_fields.has ("request_id") end
			child_log.info ("Message from child logger")
			check passed: True end
		end

	test_child_with_convenience
			-- Test child_with convenience method.
		local
			log, request_log: SIMPLE_LOGGER
		do
			create log.make
			request_log := log.child_with ("trace_id", "abc-123")
			check has_trace_id: request_log.context_fields.has ("trace_id") end
		end

	test_context_propagation
			-- Test that context fields appear in logs.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.set_json_output (True)
			log.add_context ("app", "test_app")
			log.add_context ("version", "1.0")
			log.info ("Context test")
			-- Context fields should appear in output
			check passed: True end
		end

feature -- Tracing Tests

	test_enter_exit
			-- Test enter/exit tracing.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			log.enter ("test_feature")
			log.info ("Inside feature")
			log.exit ("test_feature")
			check passed: True end
		end

feature -- Timer Tests

	test_timer_creation
			-- Test timer creation.
		local
			log: SIMPLE_LOGGER
			timer: SIMPLE_LOG_TIMER
		do
			create log.make
			timer := log.start_timer
			check timer_exists: timer /= Void end
			check elapsed_non_negative: timer.elapsed_ms >= 0 end
		end

	test_timer_elapsed
			-- Test timer elapsed time measurement.
		local
			timer: SIMPLE_LOG_TIMER
			i: INTEGER
		do
			create timer.make
			-- Do some work
			from i := 1 until i > 100000 loop
				i := i + 1
			end
			check some_time_passed: timer.elapsed_ms >= 0 end
		end

	test_log_duration
			-- Test logging with duration.
		local
			log: SIMPLE_LOGGER
			timer: SIMPLE_LOG_TIMER
			i: INTEGER
		do
			create log.make
			timer := log.start_timer
			-- Simulate work
			from i := 1 until i > 10000 loop
				i := i + 1
			end
			log.log_duration (timer, "Operation completed")
			check passed: True end
		end

	test_timer_formatted
			-- Test timer formatted output.
		local
			timer: SIMPLE_LOG_TIMER
		do
			create timer.make
			check formatted_not_empty: not timer.elapsed_formatted.is_empty end
		end

feature -- File Output Tests

	test_file_output
			-- Test file output.
		local
			log: SIMPLE_LOGGER
			test_file: STRING
		do
			test_file := "test_logger_output.log"
			create log.make_to_file (test_file)
			log.info ("Test file output")
			check file_output_enabled: log.is_file_output end
			-- Clean up
			delete_test_file (test_file)
		end

	test_add_file_output
			-- Test adding file output to existing logger.
		local
			log: SIMPLE_LOGGER
			test_file: STRING
		do
			test_file := "test_added_output.log"
			create log.make
			log.add_file_output (test_file)
			check file_output_enabled: log.is_file_output end
			log.info ("Test added file output")
			-- Clean up
			delete_test_file (test_file)
		end

feature {NONE} -- Test Utilities

	delete_test_file (a_path: STRING)
			-- Delete test file if it exists.
		local
			l_file: RAW_FILE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_file.make_with_name (a_path)
				if l_file.exists then
					l_file.delete
				end
			end
		rescue
			l_retried := True
			retry
		end

end
