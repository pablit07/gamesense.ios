#!/usr/local/bin/node

var moment = require('moment');
var fs = require('fs');
var us = require('underscore');

if (process.argv.length != 5) {
	console.log('Usage: node index.js <data file path> <questions file path> <answer key path>');
	return;
}
var separator = '\t';
var filePath = process.argv[2];
var questionFilePath = process.argv[3];
var answerFilePath = process.argv[4];

var datafile = fs.readFileSync(filePath);

if (!datafile || !datafile.length) {
	console.log('Error opening file or file is empty.');
	return;
}

var questionfile = fs.readFileSync(questionFilePath);

if (!questionfile || !questionfile.length) {
	console.log('Error opening file or file is empty.');
	return;
}

var answerfile = fs.readFileSync(answerFilePath);

if (!answerfile || !answerfile.length) {
	console.log('Error opening file or file is empty.');
	return;
}

var data = JSON.parse(datafile);
var questions = JSON.parse(questionfile);
var answers = JSON.parse(answerfile);
var rows = 0;

var headers = ['time_video_started', 'Type Response', 'Name / ID', 'Test ID', 'time_answered', 'Pitch', 'Location Response', 'Occlusion', 'Location Score', 'Type Score', 'Completely Correct']
headers.forEach(header => { process.stdout.write(header + ',')});
process.stdout.write('\n');

data.forEach(response => {
	var currentQuestion = us.find(questions, x => x.id === response.question_id);
	response.response_location = us.find(currentQuestion.response_uris[1], x => x.id === response.response_location);
	response.response_location = response.response_location.name;
	response.response_id = us.find(currentQuestion.response_uris[0], x => x.id === response.response_id);
	if (!response.response_id) {
		console.log('Response Type Not Found On Question: ' + currentQuestion);
		process.exit(1);
	}
	response.response_id = response.response_id.name;
	response.question_id = currentQuestion.occluded_video_file.substring(0, currentQuestion.occluded_video_file.length - 4);

	var currentAnswer = us.find(answers, x => x.question_id === response.question_id);

	if (!currentAnswer) {
		console.log('Not Found: ' + response.question_id);
		process.exit(1);
	} else {
		response.occlusion = currentAnswer.occlusion;
		response.location_score = (response.response_location === currentAnswer.response_location) ? 1 : 0;
		response.type_score = (response.response_id === currentAnswer.response_id) ? 1 : 0;
		response.total_score = (response.location_score === 1 && response.type_score === 1) ? 1 : 0;
	}

	Object.keys(response).forEach(key => {
		if (key == 'time_answered' || key == 'time_video_started') {
			response[key] = moment(response[key]).format('MMMM Do YYYY h:mm:ss a');
		}
		process.stdout.write(response[key] + ',');
	});
	process.stdout.write('\n');
});