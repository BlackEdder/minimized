# Minimized

Library for (multi)dimensional minimization written in D. Currently limited to an implementation of adaptive differential evolution as explained in:

Brest, J., S. Greiner, B. Boskovic, M. Mernik, and V. Zumer. ‘Self-Adapting Control Parameters in Differential Evolution: A Comparative Study on Numerical Benchmark Problems’. IEEE Transactions on Evolutionary Computation 10, no. 6 (December 2006): 646–57. doi:10.1109/TEVC.2006.872133.

`````D
import minimized;

void main()
{
    // Function to minimize
    auto fn = ( double[] xs ) {
        auto p = [ 1.0, 2.0, 10, 20, 30 ];
        return p[2] * (xs[0] - p[0]) * (xs[0] - p[0]) +
            p[3] * (xs[1] - p[1]) * (xs[1] - p[1]) + p[4];
    };

    // Function which will create random initial sets of parameters 
    auto initFunction = ()
    {
        return [ uniform( 0.0, 10.0 ), uniform( 0.0, 10.0 )];
    };

    auto de = new DifferentialEvolution!(double[])();
    de.temperatureFunction = fn;
    de.randomIndividual = initFunction;

    auto min = de.minimize;

    assert( equal!approxEqual( min, [ 1, 2 ] ) );
}
```
