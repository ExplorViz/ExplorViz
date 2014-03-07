/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2014 by
 * + Christian-Albrechts-University of Kiel
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.kiml.options;

/**
 * Enumeration for the definition of a side of the edge to place the (edge) label to. Currently
 * supported in orthogonal edge routing.
 * 
 * @author jjc
 */
public enum LabelSide {
    /** The label's placement side hasn't been decided yet. */
    UNKNOWN,
    /** The label is placed above the edge. */
    ABOVE,
    /** The label is placed below the edge. */
    BELOW;
}
