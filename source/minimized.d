module minimized;

import std.algorithm : swapAt;
import std.math : isNaN, approxEqual;
import std.range : front, popFront, isRandomAccessRange;
import std.random : uniform, rndGen, isUniformRNG;
import std.exception : enforce;

version( unittest )
{
    import std.stdio : writeln;
    import std.algorithm : equal;
}

private void partialShuffle(Range, RandomGen)(Range r, in size_t n, ref RandomGen gen)
    if(isRandomAccessRange!Range && isUniformRNG!RandomGen)
{
    enforce(n <= r.length, "n must be <= r.length for partialShuffle.");
    foreach (i; 0 .. n)
    {
        swapAt(r, i, i + uniform(0, r.length - i, gen));
    }
}

private void partialShuffle(Range)(Range r, in size_t n)
    if(isRandomAccessRange!Range)
{
    return partialShuffle(r, n, rndGen);
}

private struct Individual( RANGE )
{
    double temperature;
    RANGE parameters;

    /// Holds f and cr control parameters;
    double[] evolutionControl;
}

class DifferentialEvolution( RANGE )
{
    double function( RANGE parameters ) temperatureFunction;

    RANGE function() randomIndividual;

    RANGE minimize() 
    {
        Individual!RANGE[] population;

        double tau1 = 0.1;
        double tau2 = 0.1;

        foreach( i; 0..(10*randomIndividual().length) )
        {
            auto pars = randomIndividual();
            auto individual = Individual!RANGE( temperatureFunction( pars ),
                    pars );

            individual.evolutionControl = [uniform( 0.1, 1.2 ),
                uniform( 0.0, 1.0 )];

            population ~= individual;

            if ( bestFit.temperature.isNaN || bestFit.temperature >= individual.temperature )
                bestFit = individual;
        }

        size_t sinceAccepted = 0;

        while( sinceAccepted < 10 )
        {
            Individual!RANGE[] processed;
            Individual!RANGE[] toProcess = population;
            bool anyAccepted = false;
            foreach( _; 0..toProcess.length )
            {
                auto x = toProcess.front;
                toProcess.popFront;

                auto abc = (processed ~ toProcess);

                abc.partialShuffle( 3 );

                size_t chosenR = uniform( 0, x.parameters.length-1 );

                Individual!RANGE y;
                if (uniform(0.0,1.0)<tau1)
                    y.evolutionControl ~= uniform(0.1,1.2);
                else
                    y.evolutionControl ~= x.evolutionControl[0];
                if (uniform(0.0,1.0)<tau2)
                    y.evolutionControl ~= uniform(0.0,1.0);
                else
                    y.evolutionControl ~= x.evolutionControl[1];



                foreach( i; 0..(x.parameters.length ) )
                {
                    if ( i == chosenR 
                            || uniform(0.0,1.0) < y.evolutionControl[1] )
                        y.parameters ~= abc[0].parameters[i]
                            + y.evolutionControl[0]
                            *( abc[1].parameters[i] 
                                    - abc[2].parameters[i] );
                    else
                        y.parameters ~= x.parameters[i];
                }
                y.temperature = temperatureFunction( y.parameters );

                if ( y.temperature < x.temperature )
                {
                    anyAccepted = true;
                    processed ~= y;
                    if (y.temperature < bestFit.temperature)
                        bestFit = y;
                } else {
                    processed ~= x;
                }
            }

            if (!anyAccepted)
                sinceAccepted++;
            else 
            {
                sinceAccepted = 0;
                population = processed;
            }
        }

        return bestFit.parameters;
    }

    private:
        Individual!RANGE bestFit;
}

///
unittest
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
