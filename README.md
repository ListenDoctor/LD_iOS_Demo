
# [Listen.Doctor](https://listen.doctor) iOS integration Demo

## Where to start

### Important files

* ****APIManager****: An implementation of the [API Docs](https://api-beta.listen.doctor/developers)

* ****AudioManager****: An example on how to record or stream audio

* ****WSManager****: An example on how to implement socket communication

### Demo

1. Set all necessary credentials in the project ****ListenDoctorIosIntegrationDemoApp.swift**** or directly in the app in the Settings view

2. The demo app allows to:

* To set transcription language, speciality and desired template

* Record an audio file to receive the transcription and a summary

* Upload an audio file to receive the transcription and a summary

* Stream audio audio to receive the transcription and a summary

* Upload lab / medical documents to get a summary of them

## · Dependencies

* ****SPM****:

	* [SocketIO](https://github.com/socketio/socket.io-client-swift): Used for socket communication, streaming, etc
