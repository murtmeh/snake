function createSnake () {
    hetaOrmen = []
    alive = true
    SnakeX = 1
    SnakeY = 2
    for (let index = 0; index < snakeLength; index++) {
        newSprite = game.createSprite(2, SnakeY)
        hetaOrmen.push(newSprite)
        SnakeX += -1
    }
    setBrightness()
}
input.onButtonPressed(Button.A, function () {
    hetaOrmen[0].turn(Direction.Left, 90)
    direction += -1
    if (direction < 0) {
        direction = 3
    }
})
function setBrightness () {
    for (let index = 0; index <= hetaOrmen.length - 1; index++) {
        hetaOrmen[index].set(LedSpriteProperty.Brightness, 255 - index * (255 / snakeLength))
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
    kollakolission()
}
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
input.onButtonPressed(Button.B, function () {
    hetaOrmen[0].turn(Direction.Right, 90)
    direction += 1
    if (direction > 3) {
        direction = 0
    }
})
function kollakolission () {
    i = 1
    for (let index = 0; index < snakeLength - 1; index++) {
        if (hetaOrmen[0].get(LedSpriteProperty.X) == hetaOrmen[i].get(LedSpriteProperty.X) && hetaOrmen[0].get(LedSpriteProperty.Y) == hetaOrmen[i].get(LedSpriteProperty.Y)) {
            alive = false
            basic.clearScreen()
            basic.showIcon(IconNames.Skull)
        }
        i += 1
    }
}
let i = 0
let exitWall = 0
let head: game.LedSprite = null
let tail: game.LedSprite = null
let moveY = 0
let moveX = 0
let newSprite: game.LedSprite = null
let SnakeY = 0
let SnakeX = 0
let alive = false
let hetaOrmen: game.LedSprite[] = []
let direction = 0
let snakeLength = 0
snakeLength = 4
let timePaused = 750
direction = 0
music.setVolume(255)
createSnake()
basic.forever(function () {
    if (alive == true) {
        moveSnake()
    }
    basic.pause(timePaused)
})
