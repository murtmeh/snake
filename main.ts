function sendDisplayState () {
    displayStateMsg = "1" + ";" + control.deviceSerialNumber()
    for (let displayIndex of hetaOrmen) {
        displayStateMsg = "" + displayStateMsg + ";" + displayIndex.get(LedSpriteProperty.X) + "," + displayIndex.get(LedSpriteProperty.Y) + "," + displayIndex.get(LedSpriteProperty.Brightness)
    }
    displayStateMsg = "" + displayStateMsg + ";"
    sendList = splitMsg(displayStateMsg)
    for (let value of sendList) {
        radio.sendString("" + (value))
    }
}
function sendButtonPress (button: string) {
    buttonPressMsg = "2" + ";" + control.deviceSerialNumber() + ";" + button + ";"
    sendListButton = splitMsg(buttonPressMsg)
    for (let value2 of sendListButton) {
        radio.sendString("" + (value2))
    }
}
function createSnake () {
    hetaOrmen = []
    alive = true
    SnakeX = 1
    SnakeY = 2
    for (let index = 0; index < snakeLength; index++) {
        newSprite = game.createSprite(SnakeX, SnakeY)
        hetaOrmen.push(newSprite)
        SnakeX += -1
    }
    setBrightness()
}
input.onButtonPressed(Button.A, function () {
    if (!(isRelay)) {
        hetaOrmen[0].turn(Direction.Left, 90)
        direction += -1
        if (direction < 0) {
            direction = 3
        }
        sendButtonPress("A")
    } else {
    	
    }
})
function splitMsg (msg: string) {
    let chunks: string[] = []
    chunkCount = Math.ceil(msg.length / 18)
    for (let index2 = 0; index2 <= chunkCount - 1; index2++) {
        if (index2 == chunkCount - 1) {
            chunks.push("" + msg.substr(index2 * 18, 18) + "!")
        } else {
            chunks.push("" + msg.substr(index2 * 18, 18) + ":")
        }
    }
    return chunks
}
function setBrightness () {
    for (let index3 = 0; index3 <= hetaOrmen.length - 1; index3++) {
        hetaOrmen[index3].set(LedSpriteProperty.Brightness, 255 - index3 * (255 / snakeLength))
    }
}
function moveSnake () {
    moveX = hetaOrmen[0].get(LedSpriteProperty.X)
    moveY = hetaOrmen[0].get(LedSpriteProperty.Y)
    tail = hetaOrmen.pop()
    moveCheck()
    tail.set(LedSpriteProperty.X, moveX)
    tail.set(LedSpriteProperty.Y, moveY)
    hetaOrmen.reverse()
    head = hetaOrmen.pop()
    hetaOrmen.reverse()
    hetaOrmen.unshift(tail)
    hetaOrmen.unshift(head)
    setBrightness()
}
input.onButtonPressed(Button.AB, function () {
    if (!(isRelay)) {
        sendButtonPress("A+B")
    } else {
    	
    }
})
function moveCheck () {
    if (hetaOrmen[0].get(LedSpriteProperty.X) >= 4 && direction == 0) {
        exitWall = 2
        hetaOrmen[0].set(LedSpriteProperty.X, 0)
    } else if (hetaOrmen[0].get(LedSpriteProperty.X) <= 0 && direction == 2) {
        exitWall = 4
        hetaOrmen[0].set(LedSpriteProperty.X, 4)
    } else if (hetaOrmen[0].get(LedSpriteProperty.Y) <= 0 && direction == 3) {
        exitWall = 1
        hetaOrmen[0].set(LedSpriteProperty.Y, 4)
    } else if (hetaOrmen[0].get(LedSpriteProperty.Y) >= 4 && direction == 1) {
        exitWall = 3
        hetaOrmen[0].set(LedSpriteProperty.Y, 0)
    } else {
        hetaOrmen[0].move(1)
    }
}
radio.onReceivedString(function (receivedString) {
    if (!(isRelay)) {
    	
    } else {
        serial.writeLine(receivedString)
    }
})
input.onButtonPressed(Button.B, function () {
    if (!(isRelay)) {
        hetaOrmen[0].turn(Direction.Right, 90)
        direction += 1
        if (direction > 3) {
            direction = 0
        }
        sendButtonPress("B")
    } else {
    	
    }
})
let exitWall = 0
let head: game.LedSprite = null
let tail: game.LedSprite = null
let moveY = 0
let moveX = 0
let chunkCount = 0
let newSprite: game.LedSprite = null
let SnakeY = 0
let SnakeX = 0
let alive = false
let sendListButton: string[] = []
let buttonPressMsg = ""
let sendList: string[] = []
let hetaOrmen: game.LedSprite[] = []
let displayStateMsg = ""
let direction = 0
let timePaused = 0
let snakeLength = 0
let isRelay = false
radio.setGroup(69)
if (input.buttonIsPressed(Button.A)) {
    isRelay = true
    basic.showLeds(`
        . . # . .
        . . # . .
        # # # # #
        # . # . #
        # . # . #
        `)
} else {
    isRelay = false
    snakeLength = 4
    timePaused = 750
    direction = 0
    music.setVolume(255)
    createSnake()
}
basic.forever(function () {
    if (!(isRelay)) {
        if (alive == true) {
            moveSnake()
            sendDisplayState()
        }
        basic.pause(timePaused)
    } else {
    	
    }
})
