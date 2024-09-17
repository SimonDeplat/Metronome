(
s.waitForBoot({
	var diapason = 440;

	var win = Window(
		"Metronome",
		Rect(
			Window.screenBounds.width * 0.1,
			Window.screenBounds.height * 0.1,
			Window.screenBounds.width * 0.8,
			Window.screenBounds.height * 0.8
		);
	);
	var stackLayout = StackLayout()
	.mode_(\stackAll);

	var folderName = thisProcess.nowExecutingPath.dirname;
	var fileList = List(0);

	var margin = 3;
	var fullScreen = false;
	var routinePlaying = false;
	var routine;
	var currentBeat = 0;

	var amp = 0.25;
	var nSteps = 8;
	var release = 0.05;
	var increaseAmount = 0;
	var increaseCycle = 1;
	var currentCycle = 0;

	var rootFreq = diapason;
	var freqMul = 1;
	var scale = \minor;
	var notes = List(0);
	var score = Array.fill(16, { nil });

	var clock = TempoClock().tempo_(bpm / 60);
	var bpm = 60;

	var mainView = UserView()
	.background_(Color.fromHexString("#ff6699ff"));
	var overlayLayout = StackLayout();
	var overlay = UserView()
	.background_(Color(0, 0, 0, 0.8))
	.layout_(overlayLayout)
	.visible_(false);

	var style = GMStyle()
	.mainColor_(Color.fromHexString("#ff6699ff"))
	.backColor_(Color.fromHexString("#ff6699ff"))
	.selectedColor_(Color.fromHexString("#ff6699ff"))
	.backgroundColor_(Color.white)
	.fontColor_(Color.white)
	.valueFontColor_(Color(0.8, 0.3, 0.5))

	.helpersColor_(Color(1.0, 0.4, 0.6, 0.25))
	.highlightColor_(Color(0, 0, 0, 0.333))

	.borderSize_(2)
	.borderColor_(Color(0.8, 0.3, 0.5))
	.secondBorderSize_(1)
	.secondBorderColor_(Color(1.0, 0.5, 0.7))
	.thirdBorderSize_(1)
	.thirdBorderColor_(Color(1.0, 0.6, 0.8));

	/////////////////
	//    TITLE    //
	/////////////////
	var titleImage = Image.openSVG(
		folderName
		+/+ "title.svg"
	);
	var title = UserView()
	.maxHeight_(150)
	.background_(Color(0.8, 0.3, 0.5))
	.drawFunc_({ |view|
		var ratio = 1;

		ratio = min(
			view.bounds.width / 720,
			view.bounds.height / 150
		);

		titleImage.free;
		titleImage = Image.openSVG(
			folderName
			+/+ "title.svg"
		)
		.scalesWhenResized_(true)
		.setSize(
			(720 * ratio).asInteger,
			(150 * ratio).asInteger,
		);

		Pen.drawImage(
			Point(
				(view.bounds.width / 2) - (titleImage.width / 2),
				0
			),
			titleImage
		);
	});

	/////////////////////
	//    MENU VIEW    //
	/////////////////////
	var getFileNames = {
		fileList = List(0);
		PathName(folderName ++ "/presets/").files.do({ |path|
			if(path.fileName.endsWith(".metro"))
			{ fileList.add(path.fileName); };
		});
	};
	var loadFile = { |fileName|
		var data = this.executeFile(folderName ++ "/presets/" ++ fileName);
		if(routinePlaying) {
			playButton.toggleDisplay;
			stopRoutine.value;
		};
		amp = data[\amp];
		ampSlider.value_(amp);
		release = data[\rel];
		relSlider.value_(release);
		freqMul = data[\freqMul];
		freqMulSelector.state_(
			[0.25, 0.5, 1, 2, 4].indexOfEqual(freqMul));
		scale = data[\scale].asSymbol;
		modeSelector.state_([
			\minor, \locrian, \major, \dorian,
			\phrygian, \lydian, \mixolydian
		].indexOfEqual(scale));
		bpm = data[\bpm];
		clock.tempo_(bpm / 60);
		bpmSlider.value_(bpm);
		nSteps = data[\nSteps];
		stepSelector.state_(nSteps - 1);
		score = data[\score];
		rootFreq = data[\rootFreq];
		updateFreq.value(rootFreq);
		increaseAmount = data[\increaseAmount];
		bpmIncreaseView.state_(
			[0, 1, 2, 3, 4, 5, 10].indexOfEqual(increaseAmount));
		increaseCycle = data[\increaseCycle];
		bpmIncreaseCycleView.state_(
			 [1, 2, 4, 8].indexOfEqual(increaseCycle));

		updatePianoRoll.value;
	};
	var saveButton = GMButton()
	.style_(style)
	.stringRatio_(0.25)
	.maxHeight_(64)
	.string_("save as preset")
	.action_({
		textField.focus(true);
		overlayLayout.index = 0;
		overlay.visible = true;
	});
	var loadButton = GMButton()
	.style_(style)
	.stringRatio_(0.25)
	.maxHeight_(64)

	.string_("load a preset")
	.action_({
		getFileNames.value;
		if(fileList.size > 0) {
			dataText.string_("Please select a preset to load :");
			dataSelector.states_(
				fileList.collect({ |string|
					string.replace(".metro", "") });
			);
			dataSelector.desindex;
			dataSelector.action_({ |index|
				loadFile.value(fileList[index]);
				overlay.visible = false;
			});
			dataSelector.maxWidth_(fileList.size.sqrt.roundUp.asInteger * 384);
			dataSelector.maxHeight_(fileList.size.sqrt.roundUp.asInteger * 128);
			overlayLayout.index = 1;
			overlay.visible = true;
		};
	});
	var deleteButton = GMButton()
	.style_(style)
	.stringRatio_(0.25)
	.maxHeight_(64)
	.string_("delete a preset")
	.action_({
		getFileNames.value;
		if(fileList.size > 0) {
			dataText.string_("Please select a preset to delete :");
			dataSelector.states_(
				fileList.collect({ |string|
					string.replace(".metro", "") });
			);
			dataSelector.desindex;
			dataSelector.action_({ |index|
				File.delete(folderName ++ "/presets/" ++ fileList[index]);
				overlay.visible = false;
			});
			dataSelector.maxWidth_(fileList.size.sqrt.roundUp.asInteger * 384);
			dataSelector.maxHeight_(fileList.size.sqrt.roundUp.asInteger * 128);
			overlayLayout.index = 1;
			overlay.visible = true;
		};
	});
	var menuContainer = UserView()
	.maxWidth_(128)
	.layout_(
		VLayout()
		.margins_(0)
		.spacing_(margin)
		.add(saveButton, 1)
		.add(loadButton, 1)
		.add(deleteButton, 1)
	);

	///////////////////////
	//    PLAY BUTTON    //
	///////////////////////
	var stopRoutine = {
		routine.stop;
		pianoRoll.beat_(0);
		routinePlaying = false;
	};
	var playButton = GMPlayButton()
	.style_(style)
	.maxWidth_(128)
	.maxHeight_(128)
	.action_({ |isPlaying|
		if(isPlaying) {
			routine = Routine({
				currentBeat = 0;
				currentCycle = 0;
				routinePlaying = true;

				loop {
					if(currentBeat < nSteps) {
						if(score[currentBeat].notNil) {
							score[currentBeat].do({ |noteIndex|
								Synth(
									\metroTic,
									[
										\freq, notes[noteIndex],
										\amp, amp,
										\rel, release
									]
								);
							});
						};
					};

					1.wait;
					currentBeat = currentBeat + 1;
					if(currentBeat >= nSteps) {
						currentBeat = 0;
						if(increaseAmount > 0) {
							currentCycle = currentCycle + 1;
							if(currentCycle == increaseCycle) {
								updateBPM.value(bpm + increaseAmount);
								currentCycle = 0;
							};
						};
					};
					pianoRoll.beat_(currentBeat);
				};
			}).play(clock);
		} {
			stopRoutine.value;
		};
	});

	/////////////////////////////
	//    FREQ & SCALE VIEW    //
	/////////////////////////////
	var chromaticNotes = (Scale.at(\chromatic).ratios ++ [2]) * diapason;
	var modes = [
		\minor, \locrian, \major, \dorian,
		\phrygian, \lydian, \mixolydian
	];
	var updateFreq = { |freq|
		var selectorIndex = -1;
		rootFreq = freq;
		getNotes.value;
		chromaticNotes.do({ |note, index|
			if(note.asInteger == freq.asInteger)
			{ selectorIndex = index; };
		});
		freqSlider.value_(freq);
		if(selectorIndex > -1)
		{ freqSelector.state_(selectorIndex); }
		{ freqSelector.desindex; };
	};

	var freqText = GMTextView()
	.style_(style)
	.string_("freq. & scale");
	var freqSlider = GMSymbolSlider()
	.style_(style)
	.min_(diapason)
	.max_(diapason * 2)
	.scale_(\exp)
	.orientation_(\horizontal)
	.displayLine_(\none)
	.value_(diapason)
	.fontRatio_(0.5)
	.displayFunction_({ |value|
		value = value * (diapason / 440);
		value.asInteger
	})
	.action_({ |value| updateFreq.value(value); });
	var freqSelector = GMMultiButton()
	.style_(style)
	.fontRatio_(0.5)
	.states_([
		"A", "Bb", "B", "C", "Db", "D",
		"Eb", "E", "F", "F#", "G", "Ab", "A"
	])
	.action_({ |index| updateFreq.value(chromaticNotes[index]); });
	var freqMulSelector = GMMultiButton()
	.style_(style)
	.fontRatio_(0.5)
	.states_(["/4", "/2", "-", "x2", "x4"])
	.state_(2)
	.action_({ |index|
		freqMul = [0.25, 0.5, 1, 2, 4][index];
		getNotes.value;
	});
	var modeSelector = GMMultiButton()
	.style_(style)
	.fontRatio_(0.35)
	.states_([
		"minor", "locrian", "major", "dorian",
		"phrygian", "lydian", "mixolydian"
	])
	.action_({ |index|
		scale = modes[index];
		getNotes.value;
	});
	var freqContainer = UserView()
	.layout_(
		VLayout()
		.spacing_(0)
		.margins_(0)
		.add(freqText, 1)
		.add(freqSlider, 2)
		.add(freqSelector, 2)
		.add(freqMulSelector, 2)
		.add(modeSelector, 2)
	);

	////////////////////
	//    AMP VIEW    //
	////////////////////
	var ampText = GMTextView()
	.style_(style)
	.string_("vol.");
	var ampSlider = GMFaderSlider()
	.style_(style)
	.value_(amp)
	.displayValue_(false)
	.minAlpha_(0.5)
	.action_({ |value| amp = value; });
	var ampContainer = UserView()
	.maxWidth_(64)
	.layout_(
		VLayout()
		.spacing_(0)
		.margins_(0)
		.add(ampText, 1)
		.add(ampSlider, 9)
	);

	////////////////////
	//    REL VIEW    //
	////////////////////
	var relText = GMTextView()
	.style_(style)

	.string_("rel.");
	var relSlider = GMFaderSlider()
	.style_(style)
	.min_(0.001)
	.max_(0.5)
	.scale_(2)
	.value_(release)
	.displayValue_(false)
	.minAlpha_(0.5)
	.action_({ |value| release = value; });
	var relContainer = UserView()
	.maxWidth_(64)
	.layout_(
		VLayout()
		.spacing_(0)
		.margins_(0)
		.add(relText, 1)
		.add(relSlider, 9)
	);

	////////////////////
	//    BPM VIEW    //
	////////////////////
	var updateBPM = { |newBPM|
		bpm = newBPM;
		clock.tempo_(bpm / 60);
		{ bpmSlider.value_(bpm.asInteger); }.defer;
	};
	var bpmSliderText = GMTextView()
	.fontRatio_(0.4)
	.style_(style)
	.string_("BPM :");
	var bpmSlider = GMSymbolSlider()
	.style_(style)
	.fontRatio_(0.5)
	.min_(60)
	.max_(480)
	.value_(bpm)
	.orientation_(\horizontal)
	.displayLine_(\none)
	.modStep_(5)
	.modStepOperator_(\add)
	.modStepPixelRange_(50)
	.modStep2_(3)
	.modStep2Operator_(\add)
	.modStep2PixelRange_(50)
	.displayHelpers_(true)
	.helpersNumber_(5)
	.helperSubdivisions_(1)
	.displayFunction_({ |value| value.asInteger })
	.action_({ |value| updateBPM.value(value); });
	var bpmSliderContainer = UserView()
	.layout_(
		HLayout()
		.spacing_(0)
		.margins_(0)
		.add(bpmSliderText, 1)
		.add(bpmSlider, 9)
	);
	var bpmText1 = GMTextView()
	.fontRatio_(0.4)
	.style_(style)
	.string_("Increase BPM by");
	var bpmText2 = GMTextView()
	.fontRatio_(0.4)
	.style_(style)
	.string_("every");
	var bpmText3 = GMTextView()
	.style_(style)
	.fontRatio_(0.4)
	.string_("cycle(s).");
	var bpmIncreaseView = GMSwitchButton()
	.style_(style)
	.states_(["0", "1", "2", "3", "4", "5", "10"])
	.action_({ |index|
		increaseAmount = [0, 1, 2, 3, 4, 5, 10][index]; });
	var bpmIncreaseCycleView = GMSwitchButton()
	.style_(style)
	.states_(["1", "2", "4", "8"])
	.action_({ |index|
		increaseCycle = [1, 2, 4, 8][index];
		currentCycle = 0;
	});
	var bpmContainer = UserView()
	.layout_(
		VLayout()
		.margins_(0)
		.spacing_(margin)
		.add(bpmSliderContainer, 1)
		.add(
			HLayout()
			.spacing_(0)
			.margins_(0)
			.add(bpmText1, 3)
			.add(bpmIncreaseView, 1)
			.add(bpmText2, 1)
			.add(bpmIncreaseCycleView, 1)
			.add(bpmText3, 1),
			1
		)
	);

	/////////////////////
	//    STEP VIEW    //
	/////////////////////
	var updatePianoRoll = {
		pianoRoll.values_(score.copyRange(0, nSteps - 1));

		case
		{ nSteps == 1 } { pianoRoll.highlights_([0]) }
		{ nSteps == 2 } { pianoRoll.highlights_([0.333]) }
		{ nSteps == 3 } { pianoRoll.highlights_([0.333]) }
		{ nSteps == 4 } { pianoRoll.highlights_([0.333]) }

		{ nSteps == 5 } { pianoRoll.highlights_([0.333, 0, 0, 0.333]) }
		{ nSteps == 6 } { pianoRoll.highlights_([0.333, 0, 0, 0.333]) }
		{ nSteps == 7 } { pianoRoll.highlights_([
			0.333, 0, 0, 0, 0.333, 0, 0
		]) }
		{ nSteps == 8 } { pianoRoll.highlights_([0.333, 0, 0, 0, 0.333]) }

		{ nSteps == 9 } { pianoRoll.highlights_([
			0.333, 0, 0, 0.333, 0, 0, 0.333
		]) }
		{ nSteps == 10 } { pianoRoll.highlights_([
			0.333, 0, 0, 0.333, 0, 0.333, 0, 0, 0.333
		]) }
		{ nSteps == 11 } { pianoRoll.highlights_([
			0.333, 0, 0, 0.333, 0, 0, 0.333, 0, 0, 0.333
		]) }
		{ nSteps == 12 } { pianoRoll.highlights_([
			0.333, 0, 0, 0, 0.333, 0, 0, 0, 0.333
		]) }

		{ nSteps == 13 } { pianoRoll.highlights_([
			0.333, 0, 0, 0.333, 0, 0, 0.333, 0, 0, 0.333
		]) }
		{ nSteps == 14 } { pianoRoll.highlights_([
			0.333, 0, 0, 0, 0.333, 0, 0,
			0.333, 0, 0, 0, 0.333
		]) }
		{ nSteps == 15 } { pianoRoll.highlights_([
			0.333, 0, 0, 0.333, 0,
			0.333, 0, 0, 0.333, 0,
			0.333, 0, 0, 0.333
		]) }
		{ nSteps == 16 } { pianoRoll.highlights_([
			0.333, 0, 0, 0,
			0.333, 0, 0, 0,
			0.333, 0, 0, 0,
			0.333
		]) };
	};
	var stepText = GMTextView()
	.fontRatio_(0.4)
	.style_(style)
	.string_("Steps :");
	var stepSelector = GMMultiButton()
	.style_(style)
	.fontRatio_(0.5)
	.states_((1..16).collect({ |item| item.asString }))
	.state_(nSteps - 1)
	.action_({ |index|
		nSteps = index + 1;
		updatePianoRoll.value;
	});
	var stepContainer = UserView()
	.layout_(
		HLayout()
		.margins_(0)
		.spacing_(0)
		.add(stepText, 1)
		.add(stepSelector, 9)
	);

	//////////////////////
	//    PIANO ROLL    //
	//////////////////////
	var pianoRoll = GMListPianoRoll()
	.entries_((0..14))
	.values_(List.fill(nSteps, { nil }))
	.gridWidth_(1)
	.highlights_([0.333, 0, 0, 0, 0.333, 0, 0, 0])
	.vHighlights_([
		0.333, 0, 0,
		0.666, 0, 0.333, 0, 0.333, 0, 0,
		0.666, 0, 0.333, 0, 0.333
	])
	.beat_(0)
	.actionMode_(\index)
	.style_(style)
	.action_({ |index, value| score[index] = value; });

	////////////////////
	//    OVERLAYS    //
	////////////////////
	var saveFile = { |fileName|
		var file = File((
			folderName
			++ "/presets/"
			++ fileName
			++ ".metro"
		).standardizePath, "w");

		var data = (
			bpm: bpm,
			rootFreq: rootFreq,
			freqMul: freqMul,
			scale: scale,
			nSteps: nSteps,
			amp: amp,
			rel: release,
			increaseAmount: increaseAmount,
			increaseCycle: increaseCycle,
			score: score
		);
		file.write(data.asCompileString);
		file.close;
	};
	var saveText = GMTextView()
	.style_(style)
	.fontRatio_(0.4)
	.maxHeight_(96)
	.displayFrame_(true)
	.string_("Please select a name :");
	var textField = TextField()
	.maxHeight_(96)
	.align_(\center)
	.font_(style.font);
	var doSaveButton = GMButton()
	.style_(style)
	.stringRatio_(0.4)
	.string_("save")
	.maxHeight_(96)
	.action_({
		if(textField.string != "") {
			saveFile.value(textField.string);
			overlay.visible_(false);
			textField.string_("");
		};
	});
	var cancelSaveButton = GMButton()
	.style_(style)
	.string_("cancel")
	.maxHeight_(96)
	.stringRatio_(0.4)
	.action_({
		overlay.visible_(false);
		textField.string_("");
	});

	var dataText = GMTextView()
	.style_(style)
	.fontRatio_(0.4)
	.maxHeight_(96)
	.displayFrame_(true);
	var dataSelector = GMGridButton()
	.style_(style);
	var dataCancelButton = GMButton()
	.style_(style)
	.string_("cancel")
	.maxHeight_(96)
	.stringRatio_(0.4)
	.action_({
		overlay.visible_(false);
		textField.string_("");
	});

	/////////////////
	//    SETUP    //
	/////////////////
	var getNotes = {
		var ratios = Scale.at(scale).ratios;
		notes = ratios;
		notes = notes ++ (ratios * 2);
		notes = notes ++ (ratios * 4);
		4.do({ notes.removeAt(0); });
		2.do({ notes.pop; });
		notes = notes * rootFreq;
		notes = notes * freqMul;
		notes = notes * (diapason / 440);
	};

	getNotes.value;

	SynthDef(\metroTic, { |freq = 440, amp = 0.5, rel = 0.05|
		var snd = SinOsc.ar(freq, mul: amp);
		snd = snd * EnvGen.kr(
			Env.perc(0.0, rel),
			doneAction: Done.freeSelf
		);
		snd = snd!2;
		Out.ar(0, snd);
	}).add;

	mainView.layout_(
		VLayout()
		.margins_(margin * 2)
		.spacing_(margin * 4)
		.add(title, 1)
		.add(
			VLayout()
			.add(
				HLayout()
				.margins_(margin)
				.spacing_(margin * 2)
				.add(menuContainer, 2)
				.add(playButton, 2)
				.add(freqContainer, 9)
				.add(relContainer, 1)
				.add(ampContainer, 1),
				4
			)
			.add(bpmContainer, 2)
			.add(stepContainer, 1)
			.add(pianoRoll, 8),
			9
		)
	);

	overlayLayout.add(
		UserView().layout_(
			VLayout()
			.margins_(100)
			.spacing_(margin)
			.add(saveText, 1)
			.add(textField, 1)
			.add(
				HLayout()
				.margins_(0)
				.spacing_(margin)
				.add(doSaveButton, 1)
				.add(cancelSaveButton, 1),
				1
			)
		)
	);

	overlayLayout.add(
		UserView().layout_(
			VLayout()
			.margins_(100)
			.spacing_(margin)
			.add(dataText, 1)
			.add(
				HLayout()
				.add(dataSelector),
				2)
			.add(dataCancelButton, 1)
		)
	);

	stackLayout.add(overlay);
	stackLayout.add(mainView);
	win.layout_(stackLayout);

	win.onClose_({
		if(routinePlaying)
		{ routine.stop; };
		titleImage.free;
	});

	CmdPeriod.doOnce({
		routinePlaying = false;
		win.close;
	});

	View.globalKeyDownAction_({ |view, char, mod, unicode|
		// CTRL + F
		if(unicode == 6) {
			if(fullScreen)
			{ win.endFullScreen; }
			{ win.fullScreen; };
			fullScreen = fullScreen.not;
		};

		// ESC
		if(unicode == 27) { win.close; };
	});

	win.front;
});
)

// Simon Deplat - 2024