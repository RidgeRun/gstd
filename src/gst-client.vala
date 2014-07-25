/*
 * gstd/src/gst-client.vala
 *
 * Command line utility for sending D-Bus messages to GStreamer daemon with
 *  interactive support.
 *
 * BSD License*
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided
 * that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this list of conditions and the
 *    following disclaimer.
 *
 *  - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 *    the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 *  - Neither the name of RidgeRun LLC nor the names of its contributors may be used to endorse or
 *    promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

namespace gstd
{
public class GstdCli : GLib.Object
{
	private GLib.DBusConnection conn;
	private FactoryInterface factory;
	private string active_pipe;
	private bool cli_enable = false;
	private PipelineInterface pipeline;

	/**
	 * Used as reference in option parser
	 */
	private static string obj_path; // Used in non cli mode
	private static bool _signals = false;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] _remaining_args;
	private static bool useSessionBus = false;
	# if HAVE_READLINE
	// true: This client is used by an interactive shell. false: This client is used as an interpreter of a script
	private static bool isInteractive;
	// true: If a command fails, the client process exits. Prefered for script execution.
	private static bool isStrict = false;
	# endif

	/**
	 * Application command line options
	 */
	private const OptionEntry[] options = {
		{ "session", '\0', 0, OptionArg.NONE, ref useSessionBus,
		  "Use dbus session bus.", null},

		{ "path", 'p', 0, OptionArg.STRING, ref obj_path,
		  "Pipeline path or path_id.  Required for commands that " +
		  "effect a specific pipeline.  Usage: -p <path_id>", null},

		{ "enable_signals", 's', 0, OptionArg.INT, ref _signals,
		  "Flag to enable reception of dbus signals from GStreamer " +
		  "Daemon.  Usage: -s 1", null},

		{ "", 0, 0, OptionArg.STRING_ARRAY, ref _remaining_args,
		  null, N_("[COMMANDS...]")},

		{ null}
	};

	/* Command descriptions for the help
	   Each description is: name of the command, syntax, description
	 */
	private const string[] cmds = {
		"create|"+"create <\"gst-launch like pipeline description in quotes\">|"
		  + "Creates a new pipeline and returns the dbus-path to access it",
		"destroy|"+"destroy|"+"Destroys the pipeline specified by_path(-p) or the"
		  + " active pipeline",
		"play|"+"play|"+"Sets the pipeline specified by_path(-p) or the active "
		  + "pipeline to play state",
		"ready|"+"ready|"+"Sets the pipeline specified by_path(-p) or the active "
		  + "pipeline to ready state",
		"pause|"+"pause|"+"Sets the pipeline specified by_path(-p) or the active "
		  + "pipeline to pause state",
		"null|"+"null|"+"Sets the pipeline specified by_path(-p) or active "
		  + "pipeline to null state",
		"aplay|"+"play-async|"+"Sets the pipeline to play state, it does not "
		  + "wait the change to be done",
		"aready|"+"ready-async|"+"Sets the pipeline to ready state, it does not "
		  + "wait the change to be done",
		"apause|"+"pause-async|"+"Sets the pipeline to pause state, it does not "
		  + "wait the change to be done",
		"anull|"+"null-async|"+"Sets the pipeline to null state, it does not wait "
		  + "the change to be done",
		"set|"+"set <element_name> <property_name> <data-type> <value>|"+
		  "Sets an element's property value of the pipeline\n" +
		  "\t\tSupported <data-type>s include: boolean, integer, int64, double and " +
		  "string",
		"get|"+"get <element_name> <property_name> <data_type>|"+
		  "Gets an element's property value of the pipeline",
		"get-duration|"+"get-duration|"+"Gets the pipeline duration time",
		"get-position|"+"get-position|"+"Gets the pipeline position",
		"sh|"+"sh \"<shell command with optional parameters>\"|"+
		  "Execute a shell command using interactive console",
		"get-state|"+"get-state|"+"Get the state of a specific pipeline(-p flag)"
		  + " or the active pipeline",
		"get-elem-state|"+"get-elem-state|"+"Get the state of a specific element of"
		  + "the active pipeline",
		"ping|"+"ping|"+"Shows if gstd is alive",
		"ping-pipe|"+"ping-pipe|"+"Test if the active pipeline is alive",
		"active|"+"active <path>|"+"Sets the active pipeline,if no <path> is "
		  + "passed:it returns the actual active pipeline",
		"seek|"+"seek <position[ms]>|"+"Moves current playing position to a new"
		  + " one",
		"skip|"+"skip <period[ms]>|"+"Skips a period, if period is positive: it"
		  + " moves forward, if negative: it moves backward",
		"speed|"+"speed <rate>|"+"Changes playback rate:\n" +
		  "\t\t* rate>1.0: fast-forward playback,\n" +
		  "\t\t* rate<1.0: slow-forward playback,\n" +
		  "\t\t* rate=1.0: normal speed.\n" +
		  "\t\tNegative rate causes reverse playback.",
		"step|"+"step [number of frames]|"+"Step the number of frames, if no number is provided, 1 is assumed",
		"send-eos|"+"send-eos|"+"Send an EOS event on the pipeline",
		"send-custom-event|"+"send-custom-event <custom type> <name of event>|"+
		  "Send a custom event on the pipeline. The event type can be:\n" +
		  "\t\t* UPSTREAM\n" +
		  "\t\t* DOWNSTREAM\n" +
		  "\t\t* DOWNSTREAM_OOB\n" +
		  "\t\t* BOTH\n" +
		  "\t\t* BOTH_OOB\n",
		"element-set-state|"+"element-set-state <element_name> <state>|"+
		  "Sets the element state" +
		  "\t\tSupported <state>s include: null, ready, paused, playing",
		"element-async-set-state|"+"element-async-set-state <element_name> <state>|"+
		  "Sets the element state, it does not wait the change to be done",
		"exit|"+"exit|"+"Exit/quit active console",
		"quit|"+"quit|"+"Exit/quit active console",
		# if HAVE_READLINE
		"strict|"+"strict|"+"Enable/disable strict execution mode.",
		# endif
		"version|"+"version|"+"Show gst-client version."
	};

	private string? Cmds(int idx0, int idx1)
	{
		if (idx0 >= cmds.length)
			return null;
		string[] cmd = cmds[idx0].split("|");
		return cmd[idx1];
	}

	/*
	 * Constructor
	 */
	public GstdCli (string[] args) throws GLib.Error
	{
		parse_options(args);

		/*Getting a Gstd Factory proxy object */
		conn = GLib.Bus.get_sync ((useSessionBus) ? GLib.BusType.SESSION : GLib.BusType.SYSTEM);
		factory = conn.get_proxy_sync ("com.ridgerun.gstreamer.gstd", "/com/ridgerun/gstreamer/gstd/factory");
	}

	/**
	   *Callback functions for the receiving signals
	 */

	public void Error_cb ()
	{
		stdout.printf ("Error signal received\n");
	}

	public void EoS_cb ()
	{
		stdout.printf ("End of Stream signal received\n");
	}

	public void StateChanged_cb ()
	{
		stdout.printf ("StateChanged signal received\n");
	}

	/**
	 * Console Commands Functions
	 */

	private bool pipeline_create (string ? description)
	{
		if (description == null)
		{
			stderr.printf ("Error:\nDescription between quotes(\"\") needed\n");
			return false;
		}

		try {
			string new_objpath = factory.create (description);

			if (new_objpath == "")
			{
				stderr.printf ("Error:\nFailed to create pipeline\n");
				return false;
			}

			/*Set and create the active pipeline
			   when interactive console is enabled */
			if (cli_enable)
			{
				active_pipe = new_objpath;
				create_proxypipe (active_pipe);
			}

			stdout.printf ("Pipeline path created: %s\n", new_objpath);
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			stderr.printf ("Error:\nCreating pipeline:%s\n", e.message);
			return false;
		}
	}

	private bool pipeline_destroy (PipelineInterface pipeline)
	{
		/*This needs to be reviewed, casting compiles but does not
		   function */
		try
		{
			pipeline.pipeline_destroy();
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			stderr.printf("Error:\nFailed to destroy pipe\n");
			return false;
		}
	}

	private bool pipeline_set_state(PipelineInterface pipeline, bool sync, Gst.State state)
	{
		try {
			if (sync)
			{
				bool ret = pipeline.pipeline_set_state (state, true);
				if (!ret)
				{
					stdout.printf ("Error:\nFailed to change pipeline state\n");
					return false;
				}
			}
			else
				pipeline.pipeline_set_state_async (state, false);

			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			stdout.printf ("Error:\n%s\n", e.message);
			return false;
		}
	}

	private bool pipeline_play (PipelineInterface pipeline, bool sync)
	{
		return pipeline_set_state(pipeline, sync, Gst.State.PLAYING);
	}

	private bool pipeline_ready (PipelineInterface pipeline, bool sync)
	{
		return pipeline_set_state(pipeline, sync, Gst.State.READY);
	}

	private bool pipeline_pause (PipelineInterface pipeline, bool sync)
	{
		return pipeline_set_state(pipeline, sync, Gst.State.PAUSED);
	}

	private bool pipeline_null (PipelineInterface pipeline, bool sync)
	{
		return pipeline_set_state(pipeline, sync, Gst.State.NULL);
	}

	private bool gstd_ping ()
	{
		bool ret = false;

		try {
			ret = factory.ping ();
		}
		catch (Error e)
		{
			stderr.printf ("Error:\nFailed to reach gstd!\n");
			return ret;
		}

		stdout.printf ("pong\n");
		return ret;
	}

	private bool pipeline_ping ()
	{
		if (pipeline == null)
			return false;

		try
		{
			bool result = pipeline.ping ();

			stdout.printf("Pipeline ping result = %s\n", result ? "Success" : "Failed");
			return result;
		}
		catch (Error e)
		{
			stderr.printf ("Error:\nFailed to ping pipeline!\n");
			return false;
		}
	}

	private bool pipeline_get_property (PipelineInterface pipeline,
	                                    string[] args)
	{
		if (args[1] == null || args[2] == null || args[3] == null)
		{
			stdout.printf ("Error:\nMissing argument.Execute:'help get'\n");
			return false;
		}

		string element = args[1];
		string property = args[2];

		try
		{
			bool ret = true;
			bool success;

			switch (args[3].down ())
			{
				case "boolean" :
					bool boolean_v;
					pipeline.element_get_property_boolean (element, property, out boolean_v, out success);
					if (!success)
					{
						stdout.printf("Failed to get property value");
						ret = false;
						break;
					}
					stdout.printf ("The '%s' value on element '%s' is: %s\n",
					               property, element, boolean_v ? "true" : "false");
					break;

				case "integer":
					int integer_v;
					pipeline.element_get_property_int (element, property, out integer_v, out success);
					if (!success)
					{
						stdout.printf("Failed to get property value");
						ret = false;
						break;
					}
					stdout.printf ("The '%s' value on element '%s' is: %d\n",
					               property, element, integer_v);
					break;

				case "int64":
					int64 int64_v;
					pipeline.element_get_property_int64 (element, property, out int64_v, out success);
					if (!success)
					{
						stdout.printf("Failed to get property value");
						ret = false;
						break;
					}
					stdout.printf ("The '%s' value on element '%s' is: %lld\n",
					               property, element, int64_v);
					break;

				case "double":
					double double_v;
					pipeline.element_get_property_double (element, property, out double_v, out success);
					if (!success)
					{
						stdout.printf("Failed to get property value");
						ret = false;
						break;
					}
					stdout.printf ("The '%s' value on element '%s' is: %f\n",
					               property, element, double_v);
					break;

				case "string":
					string string_v;
					pipeline.element_get_property_string (element, property, out string_v, out success);
					if (!success)
					{
						stdout.printf("Failed to get property value");
						ret = false;
						break;
					}
					stdout.printf ("The '%s' value on element '%s' is: %s\n",
					               property, element, string_v);
					break;
				case "enum":
					int integer_v;
					pipeline.element_get_property_enum (element, property, out integer_v, out success);
					if (!success)
					{
						stdout.printf("Failed to get property value");
						ret = false;
						break;
					}
					stdout.printf ("The '%s' value on element '%s' is: %d\n",
					               property, element, integer_v);
					break;
				default:
					stderr.printf ("Error:\nDatatype not supported: %s\n", args[3]);
					return false;
			}

			if (!ret)
			{
				stdout.printf ("Error:\nFailed to get property:%s\n", property);
				return false;
			}
			stdout.printf ("Ok.\n");
			return ret;
		}
		catch (Error e)
		{
			stderr.printf ("Error:\nFailed to get property:%s\n", property);
			return false;
		}
	}

	private bool pipeline_set_property (PipelineInterface pipeline,
	                                    string[] args)
	{
		bool ret;

		if (args[1] == null || args[2] == null || args[3] == null
		    || args[4] == null)
		{
			stdout.printf ("Error:\nMissing argument.Execute:'help set'\n");
			return false;
		}

		string element = args[1];
		string property = args[2];

		try
		{
			switch (args[3].down ())
			{
				case "boolean":
					bool boolean_v = bool.parse(args[4].down());
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%s\n",
					               property, element, boolean_v ? "true" : "false");
					ret = pipeline.element_set_property_boolean (element, property, boolean_v);
					break;

				case "integer":
					int integer_v = int.parse(args[4]);
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%d\n",
					               property, element, integer_v);
					ret = pipeline.element_set_property_int (element, property, integer_v);
					break;

				case "int64":
					int64 int64_v = int64.parse(args[4]);
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%lld\n",
					               property, element, int64_v);
					ret = pipeline.element_set_property_int64 (element, property, int64_v);
					break;

				case "double":
					double double_v = double.parse(args[4]);
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%f\n",
					               property, element, double_v);
					ret = pipeline.element_set_property_double (element, property, double_v);
					break;

				case "string":
					string string_v = args[4];
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%s\n",
					               property, element, string_v);
					ret = pipeline.element_set_property_string (element, property, string_v);
					break;

				case "enum":
					int integer_v = int.parse(args[4]);
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%d\n",
					               property, element, integer_v);
					ret = pipeline.element_set_property_enum (element, property, integer_v);
					break;
				case "enum-by-name":
					string string_v = args[4];
					stdout.printf ("Trying to set '%s' on element '%s' to the value:%s\n",
					               property, element, string_v);
					ret = pipeline.element_set_property_enum_by_name (element, property, string_v);
					break;
				default:
					stderr.printf ("Error:\nDatatype not supported: %s\n", args[3]);
					return false;
			}

			if (!ret)
			{
				stderr.printf ("Error:\nFailed to set property:%s\n", property);
				return false;
			}
			stdout.printf ("Ok.\n");
			return ret;
		}
		catch (Error e)
		{
			stderr.printf ("Error:\nFailed to set property:%s\n", property);
			return false;
		}
	}

	private bool pipeline_get_duration (PipelineInterface pipeline)
	{
		try
		{
			int64 time = pipeline.pipeline_get_duration ();
			if (time < 0)
			{
				stderr.printf ("Error:\nFailed to get pipeline duration\n");
				return false;
			}
			time /= 1000000;
			stdout.printf ("The duration on the pipeline is %u:%02u:%02u.%03u\n",
			               (uint)(time / (1000 * 60 * 60)),
			               (uint)((time / (1000 * 60)) % 60),
			               (uint)((time / 1000) % 60),
			               (uint)(time % 1000));
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_get_position (PipelineInterface pipeline)
	{
		try
		{
			int64 pos = pipeline.pipeline_get_position ();
			if (pos < 0)
			{
				stderr.printf ("Error:\nFailed to get position the pipeline to null\n");
				return false;
			}
			pos /= 1000000;
			stdout.printf ("The position on the pipeline is %u:%02u:%02u.%03u\n",
			               (uint)(pos / (1000 * 60 * 60)),
			               (uint)((pos / (1000 * 60)) % 60),
			               (uint)((pos / 1000) % 60),
			               (uint)(pos % 1000));
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_get_state (PipelineInterface pipeline)
	{
		try
		{
			Gst.State state = (Gst.State)(pipeline.pipeline_get_state());
			stdout.printf ("The pipeline state is: %s\n", state.to_string());
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool element_get_state ( PipelineInterface pipeline, string[] args)
	{
		if (args[1] == null)
		{
			stdout.printf ("Error:\nMissing element argument. Execute:'help element_get_state'\n");
			return false;
		}

		string element = args[1];

		try
		{
			Gst.State state = (Gst.State)(pipeline.element_get_state (element));
			stdout.printf ("The state of %s is: %s\n", element, state.to_string ());
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_seek (PipelineInterface pipeline, string[] args)
	{
		if (args[1] == null)
		{
			stdout.printf ("Error:\nMissing argument.Execute:'help seek'\n");
			return false;
		}

		int64 pos_ms = int.parse(args[1]);
		pos_ms *= 1000000;

		try
		{
			bool ret = pipeline.pipeline_seek (pos_ms, false);
			if (!ret)
			{
				stderr.printf ("Error:\nSeek fail: Media type not seekable\n");
				return false;
			}
			stdout.printf ("Ok.\n");
			return ret;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_skip (PipelineInterface pipeline, string[] args)
	{
		if (args[1] == null)
		{
			stdout.printf ("Error:\nMissing argument.Execute:'help skip'\n");
			return false;
		}

		int64 period_ms = int.parse(args[1]);
		period_ms *= 1000000;

		try
		{
			bool ret = pipeline.pipeline_skip (period_ms);
			if (!ret)
			{
				stderr.printf ("Error:\nSkip fail: Media type not seekable\n");
				return false;
			}
			stdout.printf ("Ok.\n");
			return ret;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_speed (PipelineInterface pipeline, string[] args)
	{
		if (args[1] == null)
		{
			stdout.printf ("Error:\nMissing argument.Execute:'help speed'\n");
			return false;
		}

		double rate = double.parse(args[1]);

		try
		{
			bool ret = pipeline.pipeline_set_speed (rate);
			if (!ret)
			{
				stderr.printf ("Error:\nSpeed could not be set\n");
				return false;
			}
			stdout.printf ("Ok.\n");
			return ret;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_send_eos (PipelineInterface pipeline, string[] args)
	{
		try
		{
			pipeline.pipeline_send_eos ();
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_step (PipelineInterface pipeline, string[] args)
	{
		uint64 nframes = 1;

		if (args[1] != null)
		{
			nframes = uint64.parse(args[1]);
		}

		try
		{
			pipeline.pipeline_step (nframes);
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool pipeline_send_custom_event (PipelineInterface pipeline, string[] args)
	{
		bool ret;

		if (args[1] == null || args[2] == null)
		{
			stdout.printf ("Error:\nMissing argument.Execute:'help send-custom-event'\n");
			return false;
		}

		try
		{
			ret = pipeline.pipeline_send_custom_event(args[1], args[2]);
			if (!ret)
			{
				stderr.printf ("Error:\nUnknown custom event type\n");
				return false;
			}
			stdout.printf ("Ok.\n");
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private int string_to_state (string state)
	{
		switch (state.down ())
		{
			case "null":
				return 1;

			case "ready":
				return 2;

			case "paused":
				return 3;

			case "playing":
				return 4;

			default:
				stderr.printf ("Error:\nState not supported: %s\n", state);
				return 0;
		}
	}

	private bool element_set_state (PipelineInterface pipeline,
	                                string[] args)
	{
		bool ret;
		int state;

		if (args[1] == null || args[2] == null)
		{
			stdout.printf ("Error:\nMissing argument.  Execute:'help element-set-state'\n");
			return false;
		}

		string element = args[1];
		state = string_to_state (args[2]);

		try
		{
			ret = pipeline.element_set_state (element, state, true);
			if (!ret)
			{
				stderr.printf ("Error:\nFailed to set element state: %s\n", args[2]);
				return false;
			}
			stdout.printf ("Ok.\n");
			return ret;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool element_async_set_state (PipelineInterface pipeline,
	                                      string[] args)
	{
		int state;

		if (args[1] == null || args[2] == null)
		{
			stdout.printf ("Error:\nMissing argument.  Execute:'help element-set-state'\n");
			return false;
		}

		string element = args[1];
		state = string_to_state (args[2]);

		try
		{
			pipeline.element_set_state_async (element, state, false);
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	private bool set_active (string path)
	{
		string new_active;

		if (cli_enable)
		{
			if (path[0] != '/')
			{
				new_active = "/com/ridgerun/gstreamer/gstd/pipe" + path;
			}
			else
			{
				new_active = path;
			}
			if (!create_proxypipe (new_active))
			{
				create_proxypipe (active_pipe);
				stderr.printf ("Error:\nInvalid path\n");
				return false;
			}
			active_pipe = new_active;
			stdout.printf ("Ok.\n");
			return true;
		}
		else
		{
			stderr.printf ("Error:\nThis command is exclusive for"
			               + " interactive console mode\n");
			return false;
		}
	}

	private bool get_active ()
	{
		if (cli_enable)
		{
			if (active_pipe != null)
			{
				stdout.printf ("The active pipeline path is: %s\n", active_pipe);
				stdout.printf ("Ok.\n");
				return true;
			}
			else
			{
				stderr.printf ("Error:\nThere is no active pipeline\n");
				return false;
			}
		}
		else
		{
			stderr.printf ("Error:\nCommand used only on the interactive"
			               + " console mode\n");
			return false;
		}
	}

	private bool shell (string command)
	{
		try
		{
			GLib.Process.spawn_command_line_sync(command);
			return true;
		}
		catch (GLib.SpawnError e)
		{
			stderr.printf("Fail to execute command:%s", e.message);
		}
		return false;
	}

	# if HAVE_READLINE
	private bool set_strict (string[] args)
	{
		if (args.length < 2)
		{
			stdout.printf ("Set strict failed because of missing argument\n");
			return false;
		}

		if (args[1].down() == "on")
		{
			isStrict = true;
		}
		else if (args[1].down() == "off")
		{
			isStrict = false;
		}
		else
		{
			stdout.printf ("Set strict failed because of unexpected argument '%s'\n", args[1]);
			return false;
		}

		stdout.printf ("Set strict = '%s'\n", args[1]);

		return true;
	}

	# endif

	/*
	   *Create a proxy-object of the pipeline
	 */
	public bool create_proxypipe (string ? object_path)
	{
		if (object_path == null)
			return false;

		try
		{
			/*Create a proxy-object of the pipeline */
			pipeline = conn.get_proxy_sync ("com.ridgerun.gstreamer.gstd", object_path);
			return true;
		}
		catch (Error e)
		{
			return false;
		}
	}

	/*
	   *Parse entry-options or flags:
	   *_signals:  flag to enable signals reception,
	 *           useful when executing interactive console.
	 ******obj_path:  option to specified the pipeline
	 *           when executing a single command.
	 ******_remaining_args: command to be executed remains here,
	 *                 if there is no remaining args interactive
	 *                 console is enable.
	 */
	private void parse_options (string[] args)
	{
		/*Clean up global reference variables */
		_signals = false;
		_remaining_args = null;
		obj_path = null;

		/*Parsing options */
		var opt = new OptionContext ("\n  For a list of [COMMANDS...], type: gst-client help");
		opt.set_help_enabled (true);
		opt.add_main_entries (options, null);

		try
		{
			opt.parse (ref args);
			// Create a useful pipe name, if the used parameter form -p 0 --> /com/ridgerun/gstreamer/gstd/pipe0
			if (obj_path != null && obj_path.length >= 1 && (obj_path[0] != '/'))
				obj_path = "/com/ridgerun/gstreamer/gstd/pipe" + obj_path;
		}
		catch (GLib.OptionError e)
		{
			stderr.printf ("OptionError failure: %s\n", e.message);
		}
		if (cli_enable && obj_path != null)
			active_pipe = obj_path;
	}

	/*
	 * Parse single command
	 */
	public bool parse_cmd (string[] args) throws GLib.Error
	{
		bool success = create_proxypipe(obj_path); // May only be true in interactive none cli mode
		//print (@"Create proxy pipe $(success ? "succesful" : "failed").\n");
		if (!success)
		{
			// Test: In cli mode the active_pipe must be set.
			if (args[0].down () != "create" && args[0].down () != "help"
			    && args[0].down () != "active" && args[0].down () != "quit"
			    && args[0].down () != "list-pipes" && args[0].down () != "ping"
			    && args[0].down () != "ping-pipe" && args[0].down () != "exit"
			    && args[0].down () != "ping-pipe" && args[0].down () != "version"
			    && args[0].down () != "sh" && args[0].down () != "strict"
				&& active_pipe == null)
			{
				if (cli_enable)
					stderr.printf ("There is no active pipeline." +
					               "See \"active\" or \"create\" command\n");
				else
					stderr.printf ("Pipeline path was not specified\n");
				return false;
			}
		}

		/**
		 * Remark 02/23/11 RuH
		 * Disabled signal subscription beause
		 * - There is no mainloop which could receive incoming events.
		 * - There is no mechanism which prevent repeated subscription.
		 * - How must DBus signal parameters in Vala be handled?
		 *
		   if (false && _signals && (null != pipeline))
		   {
		    //Enable the reception of signals, if _signals flag was activated
		    //print ("Signals need to be fixed! \n");
		    if (args[0].down () != "create" && args[0].down () != "help")
		    {
		        print ("Activate signals:\n");
		        pipeline.Error.connect(this.Error_cb);
		        pipeline.EoS.connect( this.EoS_cb);
		        pipeline.StateChanged.connect(this.StateChanged_cb);
		    }
		   }*/

		switch (args[0].down ())
		{
			case "create" :
				if (cli_enable)
				{
					string[] description;
					/*Join command and split it using '\"'
					   character as reference */
					description = string.joinv (" ", args).split ("\"", -1);
					return pipeline_create (description[1]);
				}
				return pipeline_create (args[1]);

			case "destroy":
				if (cli_enable)
				{
					bool ret = pipeline_destroy (pipeline);
					if (ret)
					{
						active_pipe = null;
						return true;
					}
					else
						return false;
				}
				else
					return pipeline_destroy (pipeline);

			case "play":
				return pipeline_play (pipeline, true);

			case "ready":
				return pipeline_ready (pipeline, true);

			case "pause":
				return pipeline_pause (pipeline, true);

			case "null":
				return pipeline_null (pipeline, true);

			case "aplay":
				return pipeline_play (pipeline, false);

			case "aready":
				return pipeline_ready (pipeline, false);

			case "apause":
				return pipeline_pause (pipeline, false);

			case "anull":
				return pipeline_null (pipeline, false);

			case "set":
				return pipeline_set_property (pipeline, args);

			case "get":
				return pipeline_get_property (pipeline, args);

			case "get-duration":
				return pipeline_get_duration (pipeline);

			case "get-position":
				return pipeline_get_position (pipeline);

			case "get-state":
				return pipeline_get_state (pipeline);

			case "get-elem-state":
				return element_get_state (pipeline, args);

			case "sh":
				string[] command;
				/*Join command and split it using '\"'
				   character as reference */
				command = string.joinv (" ", args).split ("\"", -1);
				return shell (command[1]);

			case "seek":
				return pipeline_seek (pipeline, args);

			case "skip":
				return pipeline_skip (pipeline, args);

			case "speed":
				return pipeline_speed (pipeline, args);

			case "step":
				return pipeline_step (pipeline, args);

			case "send-eos":
				return pipeline_send_eos (pipeline, args);

			case "send-custom-event":
				return pipeline_send_custom_event (pipeline, args);

			case "ping":
				return gstd_ping ();

			case "ping-pipe":
				return pipeline_ping ();

			case "active":
				if (args[1] == null)
				{
					/*If path was not passed, it returns the active pipeline */
					return get_active ();
				}
				else
				{
					/*Otherwise it sets the active pipeline with the new path */
					return set_active (args[1]);
				}

			case "element-set-state":
				return element_set_state (pipeline, args);

			case "element-async-set-state":
				return element_async_set_state (pipeline, args);

			case "quit":
				cli_enable = false;
				return true;

			case "exit":
				cli_enable = false;
				return true;

				# if HAVE_READLINE
			case "strict":
				return set_strict(args);

				# endif

			case "version":
				stdout.printf ("%s\n", Gstd.PACKAGE_VERSION);
				return true;

			case "help":
				int id = 0;
				if (args.length > 1)
				{
					/* Help about some command */
					while (Cmds(id, 0) != null)
					{
						if (Cmds(id, 0) == args[1])
						{
							stdout.printf ("Command: %s\n", args[1]);
							stdout.printf ("Description:\t%s\n", Cmds(id, 2));
							stdout.printf ("Syntax: %s\n", Cmds(id, 1));
							return true;
						}
						id++;
					}
					stdout.printf ("Unknown command: %s\n", args[1]);
					return false;
				}
				else
				{
					/* List of commands */
					stdout.printf ("Request the syntax of an specific command with " +
					               "\"help <command>\".\n" +
					               "This is the list of supported commands:\n");
					while (Cmds(id, 0) != null)
					{
						stdout.printf (" %s:%s%s\n", Cmds(id, 0),
						               Cmds(id, 0).length < 6 ? "\t\t" : "\t", Cmds(id, 2));
						id++;
					}
					stdout.printf ("\n");
				}
				break;

			default:
				stderr.printf ("Unkown command:%s\n", args[0]);
				return false;
		}

		return true;
	}

	# if HAVE_READLINE
	/*
	   *Interactive Console management
	 */
	public bool cli () throws GLib.Error
	{
		string[] args;

		string home = GLib.Environment.get_variable ("HOME");
		Readline.History.read (home + "/.gst-client_history");

		while (true)
		{
			/*Get the command from the stdin */
			var cmd_line = Readline.readline ((isInteractive) ? "gst-client$ " : "");

			/* we reached the end of file */
			if (cmd_line == null)
				break;

			/*Saving command on history */
			Readline.History.add (cmd_line);

			/*Removes leading and trailing whitespace */
			cmd_line.strip ();

			/*Splits string into an array */
			args = cmd_line.split (" ", -1);

			/*Execute the command */
			if (args[0] != null && !(cmd_line.length >= 1 && cmd_line[0] == '#'))
			{
				bool result = parse_cmd (args);
				if (!result && isStrict)
					return false;
			}

			/*Exit from cli */
			if (!cli_enable)
				break;
		}
		Readline.History.write (home + "/.gst-client_history");
		return true;
	}

	# endif

	/*
	 * Parse entry arguments
	 * If there are no arguments,enable interactive console.
	 */
	public bool parse (string[] remainingArgs) throws GLib.Error
	{
		# if HAVE_READLINE
		if (isInteractive)
		{
			if (remainingArgs.length > 0)
			{
				/*Parse single command */
				stdout.printf("Parse single command interactive:\n");
				return parse_cmd (remainingArgs);
			}
			else
			{
				stdout.printf("Interactive console execution:\n");
				cli_enable = true;
				return cli ();
			}
		}
		else
		{
			if (remainingArgs.length != 1)
			{
				stdout.printf ("Please define the script file name.\n");
				stdout.printf ("Furthermore you may use the standard options (signal, ...).\n");
			}
			// Let the command line interpreter read from the script file.
			//Readline.instream = FileStream.open(remainingArgs[0], "r");
			Readline.outstream = FileStream.open("/dev/null", "w");
			cli_enable = true;
			return cli ();
		}
		# else
			if (remainingArgs.length > 0)
			{
				/*Parse single command */
				return parse_cmd (remainingArgs);
			}
			else
			{
				stderr.printf("No parameters found\n");
			}


		return false;

		# endif
	}

	static int main (string[] args)
	{
		try {
			# if HAVE_READLINE
			if (args.length == 0)
				return 1;

			/*stdout.printf("args:\n");
			   foreach(string arg in args)
			   {
			    stdout.printf(arg);
			    stdout.printf("\n");
			   }*/

			// Script execution?
			isInteractive = !("interpreter" in args[0]);
			# endif
			obj_path = null;
			GstdCli cli = new GstdCli (args);

			/*Parse commands */
			if (!cli.parse (_remaining_args))
				return 1;
		}
		catch (GLib.Error e)
		{
			stderr.printf ("gst-client> Dynamic method failure\n");
			return 1;
		}

		return 0;
	}
}
}
