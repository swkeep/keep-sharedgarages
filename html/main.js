const formContainer = document.getElementById('formContainer');
const newDoorForm = document.getElementById('newDoor');
const doorlockContainer = document.getElementById('container');
const doorlock = document.getElementById('doorlock');

var formInfo = {
    vehiclename: document.getElementById('vehiclename'),
    platevalue: document.getElementById('platevalue'),
    platetype: document.getElementById('doortype'),
    job: document.getElementById('job'),
    grades: document.getElementById('grades'),
    cids: document.getElementById('cids'),
}

window.addEventListener('message', ({ data }) => {
    if (data.color) {
        doorlock.style.background = data.color;
    }
    if (data.type == "newDoorSetup") {
        data.enable ? formContainer.style.display = "flex" : formContainer.style.display = "none";
        data.enable ? doorlockContainer.style.display = "none" : doorlockContainer.style.display = "block";
        return
    }
    if (data.type == "audio") {
        var volume = (data.audio['volume'] / 10) * data.sfx
        if (volume > 1.0) {
            volume = 1.0
        }
        if (data.distance !== 0) {
            var volume = volume / data.distance
        }
        var sound = new Audio('sounds/' + data.audio['file']);
        sound.volume = volume;
        sound.play();
    } else if (data.type == "display") {
        if (data.text !== undefined) {
            doorlock.style.display = 'block';
            doorlock.innerHTML = data.text;
            doorlock.classList.add('slide-in');
        }
    } else if (data.type == "hide") {
        doorlock.classList.add('slide-out');
        setTimeout(function() {
            doorlock.innerHTML = '';
            doorlock.style.display = 'none';
            doorlock.classList.remove('slide-in');
            doorlock.classList.remove('slide-out');
        }, 1000)
    }
})

document.addEventListener('keyup', (e) => {
    if (e.key == 'Escape') {
        sendNUICB('close');
    }
});

document.getElementById('newDoor').addEventListener('submit', (e) => {
    e.preventDefault();
    sendNUICB('saveNewVehicle', {
        vehiclename: formInfo.vehiclename.value,
        platevalue: formInfo.platevalue.value,
        job: formInfo.job.value,
        grades: formInfo.grades.value,
        cids: formInfo.cids.value,
    });
})

function sendNUICB(event, data = {}, cb = () => {}) {
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8', },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => cb(resp));
}

function makeid(length) {
    var result = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for (var i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() *
            charactersLength));
    }
    return result;
}

const reandomize = document.getElementById('randomize')
reandomize.addEventListener('click', (event) => {
    const platetype = document.getElementById('platetype')
    const reandomize = document.getElementById('platevalue')

    if (platetype.value === 'none') reandomize.value = makeid(8)
    else if (platetype.value === 'PD') {
        reandomize.value = makeid(6)
        reandomize.value += 'PD'
    } else if (platetype.value === 'SP') {
        reandomize.value = makeid(6)
        reandomize.value += 'SP'
    }
});

window.onload = (event) => {
    const reandomize = document.getElementById('platevalue')
    const job = document.getElementById('job')
    reandomize.value = makeid(8)
    job.value = 'police'
};

const platetype = document.getElementById('platetype')
platetype.addEventListener('change', (event) => {
    const platetype = document.getElementById('platetype')
    const reandomize = document.getElementById('platevalue')

    if (platetype.value === 'none') reandomize.value = makeid(8)
    else if (platetype.value === 'PD') {
        reandomize.value = makeid(6)
        reandomize.value += 'PD'
    } else if (platetype.value === 'SP') {
        reandomize.value = makeid(6)
        reandomize.value += 'SP'
    }
});