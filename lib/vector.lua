function add(p, q)
    return {p[1] + q[1], p[2] + q[2]}
end

function mult(v, s)
    return {v[1] * s, v[2] * s}
end

function neg(p)
    return {-p[1], -p[2]}
end

function apos(pos)
    return {pos.x, pos.y}
end

return {add = add, mult = mult, neg = neg, apos = apos}