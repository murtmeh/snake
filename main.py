function sendSnake (receiver: string, localWall: number, localExitPos: number) {
    if (localWall == 1) {
        exitWall = 3
    } else if (localWall == 2) {
        exitWall = 4
    } else if (localWall == 3) {
        exitWall = 1
    } else {
        exitWall = 2
    }
    // protocol-number, ...
    // 
    // 0,
    // receiver,
    // sender,
    // wall-id,
    // position,
    // snake-length
    radio.sendString("0" + "," + thisID + "," + thisID + "," + exitWall + "," + localExitPos + "," + snakeLength)
    hetaOrmen = []
}
function createSnake (headX: number, headY: number, direction: number) {
    SnakeX = 1
    SnakeY = 2
    for (let index = 0; index < snakeLength; index++) {
        newSprite = game.createSprite(SnakeX, SnakeY)
        newSprite.set(LedSpriteProperty.Direction, direction)
        hetaOrmen.push(newSprite)
        SnakeX += -1
    }
    setBrightness()
}
input.onButtonPressed(Button.A, function () {
    if (alive == true && hetaOrmen.length != 0) {
        hetaOrmen[0].turn(Direction.Left, 90)
        direction += -1
        if (direction < 0) {
            direction = 3
        }
    }
})
function initGame (myId: string) {
    // protocol 3
    // 
    // 3,
    // myId,
    radio.sendString("3" + "," + myId)
}
function setBrightness () {
    for (let index2 = 0; index2 <= hetaOrmen.length - 1; index2++) {
        hetaOrmen[index2].set(LedSpriteProperty.Brightness, 255 - index2 * (255 / snakeLength))
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
// //     1
// //   #####
// // 4 ##### 2
// //   #####
//        3
// 0 is "not specified"
function moveCheck () {
    if (hetaOrmen[0].get(LedSpriteProperty.X) >= 4 && direction == 0) {
        sendSnake("0", 2, hetaOrmen[0].get(LedSpriteProperty.Y))
        hetaOrmen = []
    } else if (hetaOrmen[0].get(LedSpriteProperty.X) <= 0 && direction == 2) {
        sendSnake("0", 4, hetaOrmen[0].get(LedSpriteProperty.Y))
    } else if (hetaOrmen[0].get(LedSpriteProperty.Y) <= 0 && direction == 3) {
        sendSnake("0", 1, hetaOrmen[0].get(LedSpriteProperty.X))
    } else if (hetaOrmen[0].get(LedSpriteProperty.Y) >= 4 && direction == 1) {
        sendSnake("0", 3, hetaOrmen[0].get(LedSpriteProperty.X))
    } else {
        hetaOrmen[0].move(1)
    }
}
radio.onReceivedString(function (receivedString) {
    radioRecieve = receivedString.split(",")
    if (radioRecieve[0] == "0") {
        // if packet[3], which is the wall is 1, 3, 2 or implied 4, spawn the snake accordingly
        if (radioRecieve[3] == "1") {
            createSnake(parseFloat(radioRecieve[4]), 0, 180)
        } else if (radioRecieve[3] == "3") {
            createSnake(parseFloat(radioRecieve[4]), 4, 0)
        } else if (radioRecieve[3] == "2") {
            createSnake(4, parseFloat(radioRecieve[4]), 270)
        } else {
            createSnake(0, parseFloat(radioRecieve[4]), 90)
        }
    } else {
    	
    }
})
input.onButtonPressed(Button.B, function () {
    if (alive == true && hetaOrmen.length != 0) {
        hetaOrmen[0].turn(Direction.Right, 90)
        direction += 1
        if (direction > 3) {
            direction = 0
        }
    }
})
let radioRecieve: string[] = []
let head: game.LedSprite = null
let tail: game.LedSprite = null
let moveY = 0
let moveX = 0
let newSprite: game.LedSprite = null
let SnakeY = 0
let SnakeX = 0
let exitWall = 0
let thisID = 0
let alive = false
let hetaOrmen: game.LedSprite[] = []
let direction = 0
let snakeLength = 0
radio.setGroup(69)
snakeLength = 4
let timePaused = 750
direction = 0
hetaOrmen = []
alive = true
thisID = control.deviceSerialNumber()
initGame(thisID)
basic.forever(function () {
    if (alive == true && hetaOrmen.length != 0) {
        moveSnake()
    }
    basic.pause(timePaused)
})
