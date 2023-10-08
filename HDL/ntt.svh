// Q = Q_K*(2^Q_M)+1
// kyber: 3329 = 13*(2^8)+1
parameter Q_M=($clog2((Q-2)^Q)-1);
parameter Q_K=((Q-1)/(1<<Q_M));
parameter DATA_WIDTH=$clog2(Q);
