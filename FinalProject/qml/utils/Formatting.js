function joinWithBullet(left, right) {
    if (left && right) {
        return left + " \u2022 " + right;
    }
    return left || right || "";
}
