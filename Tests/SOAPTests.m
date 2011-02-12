//
// SOAPTests.m
// iDatacenter
//
// Created by Jakob Borg on 8/30/10.
// Copyright 2010 Jakob Borg. All rights reserved.
//

#import "SOAP.h"
#import "SOAPTests.h"
#import "NSArray+Flatten.h"

@implementation SOAPTests

- (void)testArrayFlatten
{
        NSArray *sample = [NSArray arrayWithObjects:@"v1", [NSArray arrayWithObjects:@"v2", [NSArray arrayWithObject:@"v3"], @"v4", nil], @"v5", nil];
        NSArray *correct = [NSArray arrayWithObjects:@"v1", @"v2", @"v3", @"v4", @"v5", nil];

        NSArray *result = [sample arrayByFlattening];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testXmlHeader
{
        STAssertEqualObjects([SOAP xmlHeader], @"<?xml version=\"1.0\" encoding=\"utf-8\"?>", nil);
}

- (void)testEnvelope
{
        NSDictionary *envelopeTag = [SOAP envelope];
        STAssertEqualObjects([envelopeTag objectForKey:@"tag"], @"soap:Envelope", nil);
        STAssertNil([envelopeTag objectForKey:@"content"], nil);
        NSDictionary *attributes = [envelopeTag objectForKey:@"attributes"];
        STAssertNotNil(attributes, nil);
        STAssertEqualObjects([attributes objectForKey:@"xmlns:xsi"], @"http://www.w3.org/2001/XMLSchema-instance", nil);
        STAssertEqualObjects([attributes objectForKey:@"xmlns:xsd"], @"http://www.w3.org/2001/XMLSchema", nil);
        STAssertEqualObjects([attributes objectForKey:@"xmlns:soap"], @"http://schemas.xmlsoap.org/soap/envelope/", nil);
        STAssertEqualObjects([attributes objectForKey:@"xmlns"], @"urn:vim2", nil);
}

- (void)testBody
{
        NSDictionary *envelopeTag = [SOAP body];
        STAssertEqualObjects([envelopeTag objectForKey:@"tag"], @"soap:Body", nil);
        STAssertNil([envelopeTag objectForKey:@"content"], nil);
}

- (void)testIndentString
{
        NSString *spacer = [SOAP indentForLevel:4];
        STAssertEqualObjects(spacer, @"        ", nil);
}

- (void)testRender
{
        NSMutableDictionary *envelope = [SOAP envelope];
        NSMutableDictionary *body = [SOAP body];
        [envelope setObject:body forKey:@"content"];
        NSString *rendered = [SOAP render:envelope];
        NSString *correct = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns=\"urn:vim2\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <soap:Body/>\n</soap:Envelope>\n";
        STAssertEqualObjects(rendered, correct, nil);
}

- (void)testWithArrayInBody
{
        NSMutableDictionary *envelope = [SOAP envelope];
        NSMutableDictionary *body = [SOAP body];
        NSDictionary *child1 = [NSDictionary dictionaryWithObjectsAndKeys:@"Child", @"tag", @"child1", @"content", nil];
        NSDictionary *child2 = [NSDictionary dictionaryWithObjectsAndKeys:@"Child", @"tag", @"child2", @"content", nil];
        NSArray *array = [NSArray arrayWithObjects:child1, child2, nil];
        NSDictionary *children = [NSDictionary dictionaryWithObjectsAndKeys:@"Children", @"tag", array, @"content", nil];
        [body setObject:children forKey:@"content"];
        [envelope setObject:body forKey:@"content"];
        NSString *rendered = [SOAP render:envelope];
        NSString *correct = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns=\"urn:vim2\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <soap:Body>\n    <Children>\n      <Child>child1</Child>\n      <Child>child2</Child>\n    </Children>\n  </soap:Body>\n</soap:Envelope>\n";
        STAssertEqualObjects(rendered, correct, nil);
}

- (void)testRequestWithParameter
{
        NSDictionary *child1 = [NSDictionary dictionaryWithObjectsAndKeys:@"Child", @"tag", @"child1", @"content", nil];
        NSDictionary *child2 = [NSDictionary dictionaryWithObjectsAndKeys:@"Child", @"tag", @"child2", @"content", nil];
        NSArray *array = [NSArray arrayWithObjects:child1, child2, nil];
        NSDictionary *children = [NSDictionary dictionaryWithObjectsAndKeys:@"Children", @"tag", array, @"content", nil];
        NSString *rendered = [SOAP renderRequestWithParameter:children];
        NSString *correct = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns=\"urn:vim2\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <soap:Body>\n    <Children>\n      <Child>child1</Child>\n      <Child>child2</Child>\n    </Children>\n  </soap:Body>\n</soap:Envelope>\n";
        STAssertEqualObjects(rendered, correct, nil);
}

- (void)testTagToDictionary1
{
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"content", @"name", @"tag", nil];
        NSDictionary *corrent = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"name", nil];

        NSDictionary *result = [SOAP tagToValue:sample];

        STAssertEqualObjects(result, corrent, nil);
}

- (void)testTagToDictionary2
{
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"tag",
                                [NSArray arrayWithObjects:
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"t1", @"tag", @"v1", @"content", nil],
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"t1", @"tag", @"v2", @"content", nil],
                                 nil], @"content", nil];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSArray arrayWithObjects:
                                  [NSDictionary dictionaryWithObjectsAndKeys:@"v1", @"t1", nil],
                                  [NSDictionary dictionaryWithObjectsAndKeys:@"v2", @"t1", nil],
                                  nil], @"name", nil];

        NSDictionary *result = [SOAP tagToValue:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testTagToDictionary3
{
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"tag",
                                [NSArray arrayWithObjects:
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"t1", @"tag", @"v1", @"content", nil],
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"t2", @"tag", @"v2", @"content", nil],
                                 nil], @"content", nil];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"v1", @"t1", @"v2", @"t2", nil],
                                 @"name", nil];

        NSDictionary *result = [SOAP tagToValue:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testTagToDictionary4
{
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:@"name", @"tag",
                                [NSArray arrayWithObjects:
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"t1", @"tag", @"v1", @"content", nil],
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"t1", @"tag", @"", @"content", nil],
                                 nil], @"content", nil];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSArray arrayWithObjects:
                                  [NSDictionary dictionaryWithObjectsAndKeys:@"v1", @"t1", nil],
                                  [NSDictionary dictionaryWithObjectsAndKeys:@"", @"t1", nil],
                                  nil], @"name", nil];

        NSDictionary *result = [SOAP tagToValue:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testFlattenDictionary1 // One dimenstional dictionary should be unchanged
{
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:@"obj1", @"key1", @"obj2", @"key2", nil];

        NSDictionary *result = [SOAP flattenDictionary:sample];

        STAssertEqualObjects(result, sample, nil);
}

- (void)testFlattenDictionary2 // Keys should be flattened as far as possible
{
        NSDictionary *sample = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDictionary dictionaryWithObjectsAndKeys:@"obj1", @"key1", @"obj2", @"key2", nil], @"group1",
                                [NSDictionary dictionaryWithObjectsAndKeys:@"obj3", @"key1", [NSDictionary dictionaryWithObject:@"test" forKey:@"child"], @"key2", nil], @"group2",
                                nil];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"obj1", @"group1.key1", @"obj2", @"group1.key2",
                                 @"obj3", @"group2.key1", @"test", @"group2.key2.child",
                                 nil];

        NSDictionary *result = [SOAP flattenDictionary:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testFlattenDictionary4 // NSArray containing unique dictionary objects should be merged
{
        NSDictionary *sample = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                                   [NSDictionary dictionaryWithObject:@"v1" forKey:@"k1"],
                                                                   [NSDictionary dictionaryWithObject:@"v2" forKey:@"k2"],
                                                                   nil] forKey:@"objects"];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"v1", @"objects.k1",
                                 @"v2", @"objects.k2",
                                 nil];

        NSDictionary *result = [SOAP flattenDictionary:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testFlattenDictionary5 // NSArray containing identical dictionary keys should be merged
{
        NSDictionary *sample = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                                   [NSDictionary dictionaryWithObject:@"v1" forKey:@"k1"],
                                                                   [NSDictionary dictionaryWithObject:@"v2" forKey:@"k1"],
                                                                   [NSDictionary dictionaryWithObject:@"v3" forKey:@"k1"],
                                                                   nil] forKey:@"objects"];
        NSDictionary *correct = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:@"v1", @"v2", @"v3", nil] forKey:@"objects.k1"];

        NSDictionary *result = [SOAP flattenDictionary:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testFlattenDictionary6 // NSArray containing nearly identical dictionary keys should be merged
{
        NSDictionary *sample = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                                   [NSDictionary dictionaryWithObject:@"v1" forKey:@"k1"],
                                                                   [NSDictionary dictionaryWithObject:@"v2" forKey:@"k1"],
                                                                   [NSDictionary dictionaryWithObject:@"v3" forKey:@"k2"],
                                                                   [NSDictionary dictionaryWithObject:@"v4" forKey:@"k2"],
                                                                   [NSDictionary dictionaryWithObject:@"v5" forKey:@"k3"],
                                                                   [NSDictionary dictionaryWithObject:@"v6" forKey:@"k4"],
                                                                   nil] forKey:@"objects"];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSArray arrayWithObjects:@"v1", @"v2", nil], @"objects.k1",
                                 [NSArray arrayWithObjects:@"v3", @"v4", nil], @"objects.k2",
                                 @"v5", @"objects.k3",
                                 @"v6", @"objects.k4",
                                 nil];

        NSDictionary *result = [SOAP flattenDictionary:sample];

        STAssertEqualObjects(result, correct, nil);
}

- (void)testFlattenDictionary7 // NSArray containing NSArray child should be flattened
{
        NSDictionary *sample = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:
                                                                   [NSDictionary dictionaryWithObject:
                                                                    [NSDictionary dictionaryWithObject:@"v1" forKey:@"k1"]
                                                                                               forKey:@"net"],
                                                                   [NSDictionary dictionaryWithObject:
                                                                    [NSArray arrayWithObjects:
                                                                     [NSDictionary dictionaryWithObject:@"v2" forKey:@"k1"],
                                                                     [NSDictionary dictionaryWithObject:@"v3" forKey:@"k1"],
                                                                     nil]		       forKey:@"net"],
                                                                   nil] forKey:@"objects"];
        NSDictionary *correct = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSArray arrayWithObjects:@"v1", [NSArray arrayWithObjects:@"v2", @"v3", nil], nil], @"objects.net.k1", nil];

        NSDictionary *result = [SOAP flattenDictionary:sample];

        STAssertEqualObjects(result, correct, nil);
}

@end
