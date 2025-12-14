note
	description: "Timer for measuring operation duration in logging"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_LOG_TIMER

create
	make

feature {NONE} -- Initialization

	make
			-- Create and start timer.
		do
			create start_time.make_now
		ensure
			started: start_time /= Void
		end

feature -- Access

	start_time: SIMPLE_DATE_TIME
			-- When the timer was started.

	elapsed_ms: INTEGER_64
			-- Milliseconds elapsed since timer started.
			-- Note: Resolution is seconds due to SIMPLE_DATE_TIME precision.
		local
			l_now: SIMPLE_DATE_TIME
		do
			create l_now.make_now
			Result := (l_now.to_timestamp - start_time.to_timestamp) * 1000
		ensure
			non_negative: Result >= 0
		end

	elapsed_seconds: REAL_64
			-- Seconds elapsed since timer started (with fractional part).
		do
			Result := elapsed_ms / 1000.0
		ensure
			non_negative: Result >= 0.0
		end

	elapsed_formatted: STRING
			-- Human-readable elapsed time string.
		local
			l_ms: INTEGER_64
		do
			l_ms := elapsed_ms
			if l_ms < 1000 then
				Result := l_ms.out + "ms"
			elseif l_ms < 60000 then
				Result := (l_ms / 1000.0).truncated_to_real.out + "s"
			else
				Result := (l_ms // 60000).out + "m " + ((l_ms \\ 60000) // 1000).out + "s"
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Operations

	reset
			-- Reset the timer to current time.
		do
			create start_time.make_now
		ensure
			reset: elapsed_ms < 100 -- Should be near zero
		end

invariant
	start_time_not_void: start_time /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
